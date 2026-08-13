"""Public API (versioned under API_PREFIX).

Error contract: functions raise ApiError with a typed code.
Implementations are added session by session.
"""


class ApiError(Exception):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


# Implemented across working sessions with the project owner.
