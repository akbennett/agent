#!/bin/bash

function update_agent {
	echo "Checking current agent image sha..."
	echo "Current agent sha: $(cat /tmp/agent.sha)"
	echo "Checking for new agent container..."
	docker pull opensourcefoundries/agent:latest
	agent_current_sha=$(cat /tmp/agent.sha)
	agent_new_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
	if [ "$agent_current_sha" != "$agent_new_sha" ] ; then
		echo "New agent container detected..."
		echo "Restarting updated agent container..."
		docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name=agent_new --rm opensourcefoundries/agent:latest $1 $2
		docker stop agent
	else
		echo "No new agent container..."
	fi
}

function update {
	echo "TEST"
	echo $1 > /tmp/git.sha
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
echo "Current GIT sha: $sha"
update $sha

while true
do
	sha=($(git ls-remote $repo refs/heads/$branch))
	echo "Current GIT sha: $sha"
	current=$(cat /tmp/git.sha)
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
		agent_current_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
		echo $agent_current_sha > /tmp/agent.sha
		update_agent $repo $branch
		sleep 20
	fi
done
