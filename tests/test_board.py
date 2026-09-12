import json
from pathlib import Path
import subprocess
import tempfile
import unittest

CLI = Path(__file__).resolve().parents[1]/'scripts/anoti'

class Board(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
    def tearDown(self): self.temp.cleanup()
    def call(self, *args, ok=True, err=None):
        p = subprocess.run([str(CLI), 'board', *args], cwd=self.root, text=True, capture_output=True)
        if ok:
            self.assertEqual(p.returncode, 0, p.stderr)
            return json.loads(p.stdout)
        self.assertNotEqual(p.returncode, 0)
        # a refusal for the WRONG reason is not coverage: deleting a guard often
        # still fails, via a KeyError further down, so pin the message itself
        if err is not None:
            self.assertIn(err, p.stderr, f'expected refusal {err!r}, got: {p.stderr!r}')
    def test_delivery_and_rejection(self):
        self.call('init', 'Example')
        self.call('init', 'Overwrite', ok=False)
        item = self.call('work', 'Feature', '--description', 'Scope', '--accept', 'Verified')['id']
        # the default workflow mirrors /anoti:implement's architect-led lifecycle
        seq = [('acceptance-criteria','analyst'), ('interface-contract','architect'), (None,None),
               ('failing-tests','qa'), ('ratification','architect'), ('implementation','builder'),
               ('review','reviewer'), (None,None)]
        # an `independent` step must refuse whoever authored the step it reworks
        intruder = {'ratification': 'qa', 'review': 'builder'}
        for kind, actor in seq:
            packet = self.call('context', item)['packet']
            if kind is None:
                self.call('approve', item, '--packet', packet, '--note', 'Actual test approval')
            else:
                file = self.root/'result.json'
                file.write_text(json.dumps({'outcome':'ready','kind':kind,'body':'Fixture output','evidence':['test://fixture']}))
                self.call('submit', item, '--actor', actor, '--packet', 'stale', '--result', str(file), ok=False)
                if kind in intruder:
                    self.call('submit', item, '--actor', intruder[kind], '--packet', packet, '--result', str(file), ok=False)
                self.call('submit', item, '--actor', actor, '--packet', packet, '--result', str(file))
        self.assertEqual(self.call('list')[0]['status'], 'done')
        (self.root/'.anoti-board/BOARD.md').unlink()
        self.call('sync')
        self.assertIn('Fixture output', (self.root/'.anoti-board/BOARD.md').read_text())
    def test_rejection_routes_to_rework(self):
        self.call('init', 'Rejections')
        item = self.call('work', 'Feature', '--description', 'Scope', '--accept', 'Verified')['id']
        file = self.root/'result.json'
        def submit(kind, actor, outcome='ready'):
            packet = self.call('context', item)['packet']
            file.write_text(json.dumps({'outcome': outcome, 'kind': kind, 'body': 'x', 'evidence': ['test://fixture']}))
            return self.call('submit', item, '--actor', actor, '--packet', packet, '--result', str(file))
        submit('acceptance-criteria', 'analyst')
        submit('interface-contract', 'architect')
        packet = self.call('context', item)['packet']
        rejected = self.call('approve', item, '--packet', packet, '--note', 'Needs rework', '--reject')
        self.assertEqual(rejected['step'], 1, 'plan-approval --reject routes back to design')
        self.assertEqual(rejected['status'], 'active')
        submit('interface-contract', 'architect')
        packet = self.call('context', item)['packet']
        self.call('approve', item, '--packet', packet, '--note', 'Approved')
        submit('failing-tests', 'qa')
        # the architect's gate sends findings back to the tests, never onward
        rejected = submit('ratification', 'architect', outcome='changes_requested')
        self.assertEqual(rejected['step'], 3, 'test-ratification changes_requested routes back to acceptance-tests')
        submit('failing-tests', 'qa')
        submit('ratification', 'architect')
        # a builder disputing a test routes through the ratification step, not around it
        disputed = submit('implementation', 'builder', outcome='changes_requested')
        self.assertEqual(disputed['step'], 4, 'implementation changes_requested routes back to test-ratification')
        submit('ratification', 'architect')
        submit('implementation', 'builder')
        reviewed = submit('review', 'reviewer', outcome='changes_requested')
        self.assertEqual(reviewed['step'], 5, 'review changes_requested routes back to implementation')
        self.assertEqual(reviewed['status'], 'active')
    def test_independent_review_rejects_same_actor_across_custom_output_kind(self):
        workflow = self.root/'workflow.yaml'
        workflow.write_text('\n'.join([
            'version: 1', 'steps:',
            '  - id: build', '    type: task', '    role: backend', '    output: code',
            '  - id: review', '    type: task', '    role: reviewer', '    output: review',
            '    independent: true', '    rework: build',
            '  - id: acceptance', '    type: gate', '    rework: build', '',
        ]))
        self.call('init', 'Custom', '--workflow', str(workflow))
        item = self.call('work', 'Feature', '--description', 'Scope', '--accept', 'Verified')['id']
        file = self.root/'result.json'
        packet = self.call('context', item)['packet']
        file.write_text(json.dumps({'outcome': 'ready', 'kind': 'code', 'body': 'x', 'evidence': ['test://fixture']}))
        self.call('submit', item, '--actor', 'same-session', '--packet', packet, '--result', str(file))
        packet = self.call('context', item)['packet']
        file.write_text(json.dumps({'outcome': 'ready', 'kind': 'review', 'body': 'x', 'evidence': ['test://fixture']}))
        self.call('submit', item, '--actor', 'same-session', '--packet', packet, '--result', str(file), ok=False)
    def test_story_trace_normalises_inherits_and_stays_visible_when_absent(self):
        self.call('init', 'Traced')
        def w(title, *a, ok=True):
            return self.call('work', title, '--description', 'Scope', '--accept', 'Verified', *a, ok=ok)
        parent = w('Traced feature', '--story', 'us-004')
        self.assertEqual(parent['story'], 'US-004', 'a US-nnn id is stored canonically uppercase')
        self.assertEqual(w('Child', '--parent', parent['id'])['story'], 'US-004',
                         'decomposition inherits the parent story so it cannot escape the trace')
        self.assertEqual(w('Override', '--parent', parent['id'], '--story', 'US-007')['story'], 'US-007',
                         'an explicit story beats inheritance')
        untraced = w('Untraced')
        self.assertIsNone(untraced['story'], 'omitting --story leaves the gap visible, not defaulted')
        w('Sentinel', '--story', 'none', ok=False)  # no third state: null is the only untraced
        w('Bad id', '--story', 'US-4', ok=False)
        w('Not an id', '--story', 'the login story', ok=False)
        w('Blank', '--story', '  ', ok=False)
        listed = {i['id']: i['story'] for i in self.call('list')}
        self.assertEqual(listed[parent['id']], 'US-004', 'list carries the trace')
        self.assertIsNone(listed[untraced['id']], 'list shows untraced work as null')
        self.assertEqual({i['story'] for i in self.call('next')}, {'US-004', 'US-007', None},
                         'next surfaces the trace of every outstanding item')
        self.assertIn('Story: US-004; parent: none', (self.root/'.anoti-board/BOARD.md').read_text())
        self.assertIn('Story: untraced; parent: none', (self.root/'.anoti-board/BOARD.md').read_text())

    def test_board_predating_the_story_field_still_reads_and_rebuilds(self):
        self.call('init', 'Legacy')
        self.call('work', 'Feature', '--description', 'Scope', '--accept', 'Verified')
        state = self.root/'.anoti-board/state.json'
        data = json.loads(state.read_text())
        del data['items']['work-0001']['story']  # a board created before the trace field existed
        state.write_text(json.dumps(data, indent=2)+'\n')
        self.assertIsNone(self.call('list')[0]['story'], 'a missing key reads as untraced, not a crash')
        self.call('sync')
        self.assertIn('Story: untraced', (state.parent/'BOARD.md').read_text())
        self.assertEqual(self.call('context', 'work-0001')['context']['item'].get('story'), None)

    def test_note_invalidates_packet_and_bad_workflow(self):
        bad = self.root/'bad.yaml'; bad.write_text('version: 1\nsteps: []\n')
        self.call('init', 'Bad', '--workflow', str(bad), ok=False, err='Workflow needs ordered steps')
        self.assertFalse((self.root/'.anoti-board').exists())
        self.call('init', 'Good')
        item = self.call('work', 'Feature', '--description', 'Scope', '--accept', 'Verified')['id']
        before = self.call('context', item)['packet']
        self.call('note', item, '--actor', 'human', '--text', 'Clarification')
        self.assertNotEqual(before, self.call('context', item)['packet'])

    SEQ = [('acceptance-criteria','analyst'), ('interface-contract','architect'), (None,None),
           ('failing-tests','qa'), ('ratification','architect'), ('implementation','builder'),
           ('review','reviewer')]
    def drive(self, item):
        """advance an item to the terminal acceptance gate"""
        f = self.root/f'{item}.json'
        for kind, actor in self.SEQ:
            packet = self.call('context', item)['packet']
            if kind is None:
                self.call('approve', item, '--packet', packet, '--note', 'approved')
            else:
                f.write_text(json.dumps({'outcome':'ready','kind':kind,'body':'x','evidence':['test://f']}))
                self.call('submit', item, '--actor', actor, '--packet', packet, '--result', str(f))

    def test_acceptance_waits_for_children_and_dependencies(self):
        self.call('init', 'Graph')
        def w(title, *a, ok=True, err=None):
            return self.call('work', title, '--description', 'S', '--accept', 'W', *a, ok=ok, err=err)
        parent = w('Parent')['id']
        child  = w('Child', '--parent', parent)['id']
        dep    = w('Prereq')['id']
        gated  = w('Needs prereq', '--depends', dep)['id']
        w('Unknown link', '--parent', 'work-9999', ok=False, err='Unknown related item')
        w('Ancestor dep', '--parent', child, '--depends', parent, ok=False,
          err='cannot depend on acceptance of its ancestor')

        self.drive(parent)
        packet = self.call('context', parent)['packet']
        self.call('approve', parent, '--packet', packet, '--note', 'premature', ok=False,
                  err='Children and dependencies must be accepted first')
        self.drive(child)
        cp = self.call('context', child)['packet']
        self.assertEqual(self.call('approve', child, '--packet', cp, '--note', 'child ok')['status'], 'done')
        packet = self.call('context', parent)['packet']
        self.assertEqual(self.call('approve', parent, '--packet', packet, '--note', 'now')['status'], 'done',
                         'a parent accepts once its children are accepted')
        w('Late child', '--parent', parent, ok=False, err='Cannot add work to an accepted parent')

        self.drive(gated)
        gp = self.call('context', gated)['packet']
        self.call('approve', gated, '--packet', gp, '--note', 'dep unfinished', ok=False,
                  err='Children and dependencies must be accepted first')

    def test_workflow_validator_rejects_malformed_definitions(self):
        gate = ['  - id: done', '    type: gate']
        task = ['  - id: build', '    type: task', '    role: backend', '    output: code']
        def wf(name, *lines):
            f = self.root/f'wf-{name}.yaml'
            f.write_text('\n'.join(['version: 1', 'steps:'] + list(lines)) + '\n')
            return str(f)
        self.call('init', 'A', '--workflow', wf('a', *task), ok=False,
                  err='must finish with human acceptance')
        self.call('init', 'B', '--workflow', wf('b', *task, *task, *gate), ok=False,
                  err='Duplicate step ID')
        self.call('init', 'C', '--workflow', wf('c', '  - id: build', '    type: task',
                  '    role: nosuchrole', '    output: code', *gate), ok=False,
                  err='Unknown Anoti role')
        self.call('init', 'D', '--workflow', wf('d', '  - id: build', '    type: task',
                  '    role: backend', '    output: code', '    rework: done', *gate), ok=False,
                  err='Rework must target an earlier step')
        # an independent step reworking to a gate has no authors to exclude
        self.call('init', 'E', '--workflow', wf('e', '  - id: g1', '    type: gate',
                  '  - id: rev', '    type: task', '    role: reviewer', '    output: review',
                  '    independent: true', '    rework: g1', *gate), ok=False,
                  err='must rework to a task step')
        # the well-formed equivalent is accepted
        self.call('init', 'F', '--workflow', wf('f', *task, '  - id: rev', '    type: task',
                  '    role: reviewer', '    output: review', '    independent: true',
                  '    rework: build', *gate))

if __name__ == '__main__': unittest.main()
