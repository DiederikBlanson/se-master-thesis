import textwrap
import csv
import os

class ResultsContainerization:
    def write_dict_to_csv(result):

        # read current db
        current_directory = os.path.dirname(os.path.abspath(__file__))
        db_csv_path = os.path.join(current_directory, 'db.csv')

        print(textwrap.dedent("""
        Containerization results (details exported to /components/ResultsContainerization/db.csv):
            - Executable: {}
            - Docker image created: {}
            - Image size: {}
            - CodeInspection time: {:.1f}s
            - Overall time: {:.1f}s
            - Error label: {}
        """.format(
            bool(result['executable']),
            bool(result['dockerfile_generated']),
            None if 'image_size' not in result else "{}MB".format(int(int(result['image_size']) / 1000000)),
            result['code-inspection-time'],
            result['overall-time'],
            None if "error-label" not in result else result["error-label"]
        )))

        keys = [
            "source_folder",
            'base_image',
            "docker_image_name",
            'image_size',
            'package_extraction',
            'dependency_installation',
            'dockerfile_generated',
            'executable',
            "dockergeneration-time-real",
            "dockergeneration-time-user",
            "dockergeneration-time-sys",
            "detected_dependencies",
            "installed_dependencies",
            "ms-base-image",
            "minimal-set",
            "advanced-dependencies",
            "extended-base",
            "code-inspection-time",
            "overall-time",
            "execution-error",
            "dockerfile-error",
            "error-label"
        ]

        with open(db_csv_path, 'a', newline='') as csv_file:
            writer = csv.writer(csv_file)
            writer.writerow([result.get(key, "-") for key in keys])