import re
import subprocess

class Utils:
    @staticmethod
    def get_additional_packages(value):
        result = ""
        pattern = r"\$\$(.+?)\$\$"
        matches = re.findall(pattern, value)

        # get the content of each match
        for match in matches:
            result += match.strip()
        if result == "":
            return []
        
        result = result.replace(' ', '').split(',')
        return result
    
    @staticmethod
    def get_code_snippet(value):
        result = ""
        pattern = r"```[a-z]{0,}([\s\S]+?)```"
        matches = re.findall(pattern, value)

        # get the content of each match
        for match in matches:
            result += match.strip()
        return result
    
    @staticmethod 
    def run_time_command(property, cmd):
        result = {}
        response = None

        try:
            process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()

            # Decode the stdout and stderr as strings
            stdout_str = stdout.decode("utf-8")
            stderr_str = stderr.decode("utf-8")

            # Error handling
            response = str(stdout).replace(", ", " ")
            if "is not available for this version of" in response:
                result["dockerfile-error"] = response
                return result

            # Extract the real, user, and system time values from the stderr
            time_output = stderr_str.strip().splitlines()
            for t in time_output:
                metric, value = t.split("\t")
                result['{}-time-{}'.format(property, metric)] = value
            process.wait()

            result['dockerfile_generated'] = 1
            return result
        except Exception as e: 
            result["dockerfile-error"] = response
            return result
    
    @staticmethod
    def get_type(value):
        if value == "str" or value == "list":
            return "character"
        elif value == "int":
            return "integer"
        elif value == "float":
            return "numeric"
        else:
            raise ValueError("Not a valid type")