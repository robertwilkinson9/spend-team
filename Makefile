all:	update-function-configuration
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
	sleep 60
update-function-configuration: update-function
	aws lambda update-function-configuration --function-name spend-team-lambda --environment "Variables={TEAM_SPEND_ALERT=$${TEAM_SPEND_ALERT}, TEAM_SPEND_ACTION=$${TEAM_SPEND_ACTION}}"
run: build
	docker run --platform linux/amd64 -p 9000:8080 --env TEAM_SPEND_ALERT=$${TEAM_SPEND_ALERT} --env TEAM_SPEND_ACTION=$${TEAM_SPEND_ACTION} spend-team-lambda:latest
