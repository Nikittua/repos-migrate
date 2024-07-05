#!/bin/bash



src_URL=$2
src_group_name=$3
dest_URL=$4
dest_group_name=$5



usage() {
    echo "Usage: $0 [options] <source> <project> <destination> <repo-path>"
    echo "Options:"
    echo "  -l, --list-repos           List repos to clone"
    echo "  -c, --clone                Clone repos (with --mirror)"
    echo "  -cp, --create-project      Create projects on dest GitLab"
    echo "  -p, --push                 Change origin and push projects"
    echo "  -f, --full                 Full execution: get, list, clone repos, create projects on dest GitLab, change remote and push (with --mirror) "
    echo "  -h, --help                 Show this help message and exit"
    exit 1
}

check_existence() {

    source_answer_code=$(curl --silent --request GET --header "PRIVATE-TOKEN: $SOURCE_TOKEN" \
    "https://${src_URL}/api/v4/groups/${src_group_name}" | awk -F\" '{print $4}' | awk '{print $1}')

    if [ "$answer_code" = "404" ]; then
        echo "Source group doesn't exist. Please try again."
        return 1
    elif [ "$answer_code" = "401" ]; then
        echo "Cannot Authorize. Check your creds and try again."
        return 1
    else
        echo "Source group exists."
    fi

    dest_answer_code=$(curl --silent --request GET --header "PRIVATE-TOKEN: $DEST_TOKEN" \
    "https://${dest_URL}/api/v4/groups/${dest_group_name}" | awk -F\" '{print $4}' | awk '{print $1}')

    if [ "$dest_answer_code" = "404" ]; then
        echo "Destination group doesn't exist. Please try again."
        return 1
    elif [ "$dest_answer_code" = "401" ]; then
        echo "Cannot Authorize. Check your creds and try again."
        return 1
    else
        echo "Destination group exists."
    fi



}


get_repos() {

group_id=$(gitlab --gitlab $src_group_name group list | head -n 1 | awk '{print $2}')

projects_ids=( $(gitlab --gitlab $src_group_name group-project list --group-id $group_id --get-all | grep id | awk '{print $2}' ) )

for i in "${projects_ids[@]}"; do
        repo=$(curl  --silent --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "https://${src_URL}/api/v4/projects/${i}" | jq -r '.ssh_url_to_repo')
        ssh_url+=("$repo")
done

}


list_repos() {
 
    #echo $group_id
    printf '%s\n' "${ssh_url[@]}"
}

clone_repos() {

#    mkdir -p repos

#    for i in "${repos_array[@]}"; do
#        echo "Cloning $i ..."
#        repo_name=$(basename "$i")
#        git clone -q --mirror "$i" "repos/$repo_name"
#    done

    mkdir -p repos

    for i in "${projects_ids[@]}"; do
        repo=$(curl  --silent --header "PRIVATE-TOKEN: $SOURCE_TOKEN" "https://${src_URL}/api/v4/projects/${i}" | jq -r '.ssh_url_to_repo')
        echo "Cloning $repo ..."
        repo_name=$(basename "$repo")
        git clone -q --mirror "$repo" "repos/$repo_name" 
    done
    wait # Ожидание окончания всех фоновых процессов


    
}



# DESTINATION REPO


create_projects() {
	
group_id=$(curl --silent --header "PRIVATE-TOKEN: $DEST_TOKEN" "https://${dest_URL}/api/v4/groups/" | jq '.[0] .id')


    for i in "${repos_array[@]}"; do
        echo "Creating project $i ..."
        repo_name=$(basename "$i" .git)
	#echo $repo_name
	curl --silent --request POST --header "PRIVATE-TOKEN: $DEST_TOKEN" \
        --data "name=$repo_name" --data "namespace_id=$group_id" \
        "https://${dest_URL}/api/v4/projects" > /dev/null 
    done


}

change_remote_and_push() {

REPOS_DIR="repos"

for REPO_DIR in "$REPOS_DIR"/*; do
  # Проверка, что это действительно директория
  if [ -d "$REPO_DIR" ]; then
    # Извлечение имени директории
    DIR_NAME=$(basename "$REPO_DIR")
    
    # Формирование нового URL
    NEW_ORIGIN_URL="git@$dest_URL:infra-openstack/$dest_group_name/$DIR_NAME"
    
    cd "$REPO_DIR"
    
    echo "Updating origin for $REPO_DIR to $NEW_ORIGIN_URL"
      
      # Удаление старого origin
    git remote remove origin
      
      # Добавление нового origin
    git remote add origin "$NEW_ORIGIN_URL"
    
    git push -q --mirror origin
    # Возвращение в начальную директорию
    cd - > /dev/null
  fi
done


}


if [ $# -eq 0 ]; then
    usage
fi

    key="$1"
    case $key in
        -c|--clone)
            if [ $# -ne 5 ]; then
                usage
            fi
            check_existence || exit 1
            get_repos
            clone_repos
            shift 5 # пропустить аргументы
            ;;
        -l|--list-repos)
            if [ $# -lt 5 ]; then
                usage
            fi
            check_existence
	    get_repos
            list_repos
            shift 5 # пропустить аргументы
            ;;
        -cp|--create-projects)
            if [ $# -lt 5 ]; then
                usage
            fi
            check_existence || exit 1
            get_repos
            create_projects
            shift 5 # пропустить аргументы
            ;;
        -p|--push)
            if [ $# -lt 5 ]; then
                usage
            fi
            change_remote_and_push
            shift 5 # пропустить аргументы
            ;;
        -f|--full)
            if [ $# -lt 5 ]; then
                usage
            fi
            check_existence || exit 1
            get_repos
	    list_repos
            clone_repos
            create_projects
            change_remote_and_push
            shift 5 # пропустить аргументы
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unrecognized option '$key'"
            usage
            ;;
        *)
            # Unexpected argument
            echo "Error: Unexpected argument: $1"
            usage
            ;;
    esac
