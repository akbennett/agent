#!/bin/bash

function update_agent {
	echo "Checking current agent image sha..."
	docker_current_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
	echo "Current agent sha: $docker_current_sha"
	echo "Checking for new agent container..."
	docker pull opensourcefoundries/agent:latest
	docker_new_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
	if [ "$docker_current_sha" != "$docker_new_sha" ] ; then
		echo "New agent container detected..."
		echo "Restarting updated agent container..."
		docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name=agent_new --rm opensourcefoundries/agent $1 $2
		docker stop agent
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

repo=$1
branch=$2
rm -rf tmp
sha=($(git ls-remote $repo refs/heads/$branch))
git clone $repo -b $branch tmp
cd tmp
echo "Current sha: $sha"
update $sha

while true
do
	sha=($(git ls-remote $repo refs/heads/$branch))
	echo "Current sha: $sha"
	current=$(cat /tmp/current.sha)
	if [ "$sha" != "$current" ] ; then
		git pull
		echo "New deployment found, updating..."
		update $sha
	else
		echo "No new deployment found..."
		if docker ps | grep agent_new
		then
			echo "Found new agent container, renaming..."
			docker rename agent_new agent
		fi
		update_agent $repo $branch
		sleep 20
	fi
done
