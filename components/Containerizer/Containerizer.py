import time
from components.Containerizer.CodeInspector.CodeInspector import CodeInspector
from components.Containerizer.CodeExecutor.CodeExecutor import CodeExecutor

class Containerizer:
    def containerize(algorithm_details, debug):
        result = algorithm_details
        result['executable'] = 0
        result['dockerfile_generated'] = 0
        result['error-label'] = None

        # generate dockerfile and also time this step
        start_time = time.time()
        result = CodeInspector.inspect(result)
        end_time = time.time()
        execution_time = end_time - start_time
        result["code-inspection-time"] = execution_time

        # an error occurred in the creation of the assets (e.g., Dockerfile)
        if 'dockerfile-error' in result:
            return result
        return CodeExecutor.execute(result, debug)