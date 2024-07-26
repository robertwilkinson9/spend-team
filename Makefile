TSA = $(shell echo $${TEAM_SPEND_ALERT} | wc -c)
# the env var returns one newline character when empty; more characters when it is set

ifeq (${TSA}, 1)
all:	update-function
else
all:	update-function-configuration
endif
login:
	aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 778666285893.dkr.ecr.eu-west-2.amazonaws.com
build: login
	docker build --platform linux/amd64 -t spend-team-lambda:latest .
tag: build
	docker tag spend-team-lambda:latest 778666285893.dkr.ecr.eu-west-2.amazonaws.com/spend-team-lambda:latest
push: tag
	docker push 778666285893.dkr.ecr.eu-west-2.amazonaws.com/spend-team-lambda:latest
list-images:
	aws ecr list-images --repository-name spend-team-lambda
update-function: push
	aws lambda update-function-code --function-name spend-team-lambda  --image-uri 778666285893.dkr.ecr.eu-west-2.amazonaws.com/spend-team-lambda:latest
update-function-configuration: update-function
	sleep 60
	aws lambda update-function-configuration --function-name spend-team-lambda --environment "Variables={TEAM_SPEND_ALERT=$${TEAM_SPEND_ALERT}, TEAM_SPEND_ACTION=$${TEAM_SPEND_ACTION}}"
run: build
ifeq (${TSA}, 1)
		docker run --platform linux/amd64 -p 9000:8080 spend-team-lambda:latest
else
		docker run --platform linux/amd64 -p 9000:8080 --env TEAM_SPEND_ALERT=$${TEAM_SPEND_ALERT} --env TEAM_SPEND_ACTION=$${TEAM_SPEND_ACTION} spend-team-lambda:latest
endif
