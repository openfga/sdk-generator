all: run

project_name=example1
openfga_version=latest

setup:
	cd "${project_name}/" && pip3 install -r requirements.txt && cd -

run: setup
	python3 "${project_name}/${project_name}.py"

run-openfga:
	docker pull docker.io/openfga/openfga:${openfga_version} && \
		docker run -p 8080:8080 docker.io/openfga/openfga:${openfga_version} run
