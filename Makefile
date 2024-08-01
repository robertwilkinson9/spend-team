all:	update-function

login:
	aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 778666285893.dkr.ecr.eu-west-2.amazonaws.com
build: login
	docker build --platform linux/amd64 -t team-spend-action:latest .
tag: build
	docker tag team-spend-action:latest 778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest
push: tag
	docker push 778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest
list-images:
	aws ecr list-images --repository-name team-spend-action
update-function: push
	aws lambda update-function-code --function-name team-spend-action  --image-uri 778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest
run: build
	docker run --platform linux/amd64 -p 9000:8080 --env AWS_ACCESS_KEY_ID=$${AWS_ACCESS_KEY_ID} --env AWS_SECRET_ACCESS_KEY=$${AWS_SECRET_ACCESS_KEY} --env AWS_SESSION_TOKEN=$${AWS_SESSION_TOKEN} team-spend-action:latest
