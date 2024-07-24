all:	update-function

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
run: build
	docker run --platform linux/amd64 -p 9000:8080 spend-team-lambda:latest
