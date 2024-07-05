
if [ -z "$SOURCE_TOKEN" ]; then
    echo "Error: SOURCE_TOKEN is not set. Please set it as an environment variable."
    exit 1
fi

if [ -z "$DEST_TOKEN" ]; then
    echo "Error: DEST_TOKEN is not set. Please set it as an environment variable."
    exit 1
fi

src_URL=$1
src_group_name=$2

usage() {
    echo "Usage: $0  <source> <project>"
    exit 1
}



prepare() {
    sudo apt install python3-dev python3-venv gcc pkg-config

    mkdir gitlab-py-venv
    python3 -m venv ~/gitlab-py-venv/

    source ~/gitlab-py-venv/bin/activate

    pip3 install python-gitlab

    # Создание файла конфигурации .python-gitlab.cfg
    cat << EOF > ~/.python-gitlab.cfg
[global]
default = $src_group_name
ssl_verify = true
timeout = 5

[$src_group_name]
url = https://${src_URL}
private_token = $SOURCE_TOKEN
api_version = 4
EOF

    wait
}


if [ $# -eq 0 ] || [ $# -ne 3 ]; then
	usage
   else
	prepare

fi

