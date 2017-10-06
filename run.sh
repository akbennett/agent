#!/bin/bash

function update_agent {
	if docker pull opensourcefoundries/agent:latest | grep 'Downloaded newer image'
	then
		echo "AGENT: Update detected..."
		echo "AGENT: Starting updated agent container..."
		docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name=agent_new --rm opensourcefoundries/agent:latest $1 $2
		echo "AGENT: This agent will self destruct in..5..4..3..2..1.."
		docker stop agent
	else
		echo "AGENT: No new agent container..."
	fi
}

function update {
	echo $1 > /tmp/git.sha
	echo "DOCKER-COMPOSE: Bringing down current container set..."
	docker-compose down
	echo "DOCKER-COMPOSE: Deleteing current container set..."
	docker-compose rm -f
	echo "DOCKER-COMPOSE: Updating current container set..."
	docker-compose pull
	echo "DOCKER-COMPOSE: Bringing up current container set.."
	docker-compose up -d
}

repo=$1
branch=$2
rm -rf tmp
sha=($(git ls-remote $repo refs/heads/$branch))
git clone $repo -b $branch tmp
cd tmp
echo "INIT: TRIGGER: SHA: $sha"
if docker ps | grep agent_new > /dev/null
then
	echo "INIT: UPDATE: Agent updated..."
	echo $sha > /tmp/git.sha
else
	echo "INIT: FIRSTBOOT: Updating current container set..."
	update $sha
fi

while true
do
	sha=($(git ls-remote $repo refs/heads/$branch))
	echo "LOOP: TRIGGER: SHA: $sha"
	current=$(cat /tmp/git.sha)
	if [ "$sha" != "$current" ] ; then
		git pull
		echo "LOOP: TRIGGER: New deployment found, updating..."
		update $sha
	else
		echo "LOOP: TRIGGER: No new deployment found..."
		if docker ps | grep agent_new > /dev/null
		then
			echo "LOOP: TRIGGER: Found new agent container, renaming..."
			docker rename agent_new agent > /dev/null
		fi
		agent_current_sha=$(docker inspect "opensourcefoundries/agent:latest" | grep Id | sed "s/\"//g" | sed "s/,//g" |  tr -s ' ' | cut -d ' ' -f3)
		echo $agent_current_sha > /tmp/agent.sha
		echo "LOOP: AGENT: Checking for new agent container..."
		update_agent $repo $branch
		sleep 20
	fi
done
