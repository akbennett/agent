#!/bin/bash

function update_agent {
	echo "Checking current image sha..."
	docker_current_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
	echo "Current agent sha: $docker_current_sha"
	echo "Checking for new agent container..."
	docker pull opensourcefoundries/agent:latest
	docker_new_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
	if [ "$docker_current_sha" != "$docker_new_sha" ] ; then
		echo "New agent container detected..."
		echo "Restarting updated agent container..."
		docker restart agent
	else
		echo "No new agent container..."
	fi
}

function update {
	echo $1 > /tmp/current.sha
	echo "Bringing down current container set..."
	docker-compose down
	echo "Deleteing current container set..."
	docker-compose rm -f
	echo "Updating current container set..."
	docker-compose pull
	echo "Bringing up current container set.."
	docker-compose up -d
}

rm -rf tmp
sha=($(git ls-remote $1 refs/heads/$2))
git clone $1 -b $2 tmp
cd tmp
echo "Current sha: $sha"
update $sha

while true
do
	sha=($(git ls-remote $1 refs/heads/$2))
	echo "Current sha: $sha"
	current=$(cat /tmp/current.sha)
	if [ "$sha" != "$current" ] ; then
		git pull
		echo "New deployment found, updating..."
		update $sha
	else
		echo "No new deployment found..."
		update_agent
		sleep 20
	fi
done
