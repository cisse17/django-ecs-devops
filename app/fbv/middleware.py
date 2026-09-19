import time
import logging


# logger = logging.getLogger(__name__)
perf_logger = logging.getLogger("performance")

class RequestTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.time()

        response = self.get_response(request)

        duration = (time.time() - start_time) * 1000  # ms
        duration = round(duration, 2)

        method = request.method
        path = request.path
        ip = request.META.get('REMOTE_ADDR')

        # logger.info(f"[REQUEST TIME] {method} {path} -> {duration} ms ")
        perf_logger.info(f"[REQUEST TIME] {method} {path} from {ip} -> {duration} ms")

        return response
    




