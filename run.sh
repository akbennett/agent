#!/bin/bash

rm -rf agent-watch
sha=($(git ls-remote $1 refs/heads/$2))
git clone $1 -b $2
cd agent-watch
echo "Current sha: $sha"
echo $sha > /tmp/current.sha
echo "Bringing down current container set..."
docker-compose down
echo "Bringing up current container set.."
docker-compose up -d

while true
do
	sha=($(git ls-remote $1 refs/heads/$2))
	echo "Current sha: $sha"
	current=$(cat /tmp/current.sha)
	if [ "$sha" != "$current" ] ; then
		git pull
		echo "New deployment found, updating..."
		echo $sha > /tmp/current.sha
		echo "Bringing down current container set..."
		docker-compose down
		echo "Bringing up current container set.."
		docker-compose up -d
	else
		echo "No new deployment found..."
		sleep 20
	fi
done
