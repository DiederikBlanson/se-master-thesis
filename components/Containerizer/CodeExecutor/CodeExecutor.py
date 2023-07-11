import os
import subprocess
import time
import pty
from dotenv import load_dotenv
from utils import Utils
load_dotenv(override=True)
from components.HiddenDependenciesDetector.HiddenDependenciesDetector import HiddenDependenciesDetector
from components.PackageSetMinimizer.PackageSetMinimizer import PackageSetMinimizer
from rpy2.robjects.packages import importr
base = importr('base')

# configurations
CHATGPT_API_KEY = os.environ.get('API_KEY')
MAX_EXECUTION_TIME = 300 # the execution of the script can take maximum 5 minutes, then the process exists

def remove_formatting(string): # Remove leading and trailing whitespaces
    string = string.strip()
    string = string.replace('\n', '')
    string = string.replace('\r', '')
    string = ' '.join(string.split())
    return string

class CodeExecutor:
    def execute(obj, debug):
        result = obj
        print("Starting the 'CodeExecution' =>")

        try:
            project_name = obj["source_folder"].split("/")[1]
            result_folder_name = 'results/{}'.format(project_name)

            # Process 1 - Delete old Docker image
            rm_image = subprocess.Popen("docker rmi {} ".format(obj["docker_image_name"]), shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            rm_image.wait()  
            print("\t- Old Docker image deleted")
                                        
            # Process 2 - Build the Docker image
            print("\t- Start building the Docker image")
            if debug == 0:                
                process = Utils.run_time_command("dockergeneration", "time docker build --no-cache -t {} -f {}/Dockerfile {}".format(obj["docker_image_name"], result_folder_name, result_folder_name))
                result.update(process)    
                if result["dockerfile_generated"] == 0:
                    return result             
            else:
                p = subprocess.Popen("docker build --no-cache -t {} -f {}/Dockerfile .".format(obj["docker_image_name"], result_folder_name), shell=True)
                p.wait()
            print("\t- Docker image created")

            # Process 3 - Get the image size
            image_size_cmd = subprocess.Popen(
                "docker image inspect " + obj["docker_image_name"] + " --format='{{.Size}}'", 
                shell=True,               
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE
            )                                  
            image_size, _ = image_size_cmd.communicate()
            result['image_size'] = image_size.decode().strip()
            print("\t- Extraction of docker image size")

            # Process 4 - Execute code in the container
            print("\t- Executing the container")
            cmd = ["docker", "run", "-it", "--rm", "-v", "{}/{}:/app".format(os.getcwd(), result_folder_name), obj["docker_image_name"], "Rscript", "/app/myScript-improved.R"]
            if "inputs" in obj:
                for input in obj["inputs"]:
                    nameInput = input["name"]
                    defaultInput = input["default"]
                    typeInput = input["type"]
                    if typeInput == "int" or typeInput == "numeric":
                        cmd.append('--{}={}'.format(nameInput, defaultInput))
                    elif typeInput == "str":
                        cmd.append('--{}={}'.format(nameInput, defaultInput))
                    elif typeInput == "list":
                        cmd.append('--{}={}'.format(nameInput, defaultInput))
            if debug == 0:
                try:
                    process3 = subprocess.Popen(cmd, stdin=pty.openpty()[0], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

                    # the execution can take maximum x amount of time
                    start_time = time.time()
                    while True:
                        if process3.poll() is not None:
                            break
                        if time.time() - start_time > MAX_EXECUTION_TIME:
                            process3.terminate()
                            print("\t- Execution Failed: execution took too long, process killed")
                            result["execution-error"] = "Execution took too long. Process killed."
                            obj["error-label"] = "EXC_TOO_LONG"
                            raise
                    out, _ = process3.communicate()

                    # analyze the response
                    return_code = process3.returncode
                    if return_code == 0:
                        result['executable'] = 1
                    else:
                        obj["execution-error"] = remove_formatting(str(out)[-200:]).replace(", ", " ")
                        if obj["advanced-dependencies"] == 1:

                            # get additional packages from chatgpt
                            chatgpt_packages = HiddenDependenciesDetector.chatgpt_packages(obj, out, CHATGPT_API_KEY)
                            
                            # in case more than one package is suggested, retry again
                            if len(chatgpt_packages) > 0:
                                HiddenDependenciesDetector.insert_hidden_dep(obj['original_dependencies'], chatgpt_packages)
                                print("\t- Execution Failed: Hidden dependencies are detected with ChatGPT, retry")
                                result['again'] = 1
                                result['error-label'] =  "HIDDEN_DEP"
                                return result
                            result["error-label"] = "RUNTIME_ERROR"
                        else: 
                            result["error-label"] = "RUNTIME_ERROR"
                except:
                    pass
            else:
                process3 = subprocess.Popen(cmd, stdin=pty.openpty()[0])
                process3.wait()
            print("\t- Execution Succeeded")

            # Process 5: Populate knowledge bases
            print("Populate knowledge bases => ...")
            PackageSetMinimizer.insert_code_analysis(obj, os.getcwd())

            # Return result
            return result
        except Exception as e:
            print("Error CodeExecution component: ", e)
            return result
