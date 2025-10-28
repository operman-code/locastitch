// Define the Declarative Pipeline
pipeline {
    // 1. ENVIRONMENT VARIABLES
    environment {
        // AWS-specific variables
        AWS_REGION = 'us-east-1' // **REPLACE THIS** with your AWS Region
        AWS_ACCOUNT_ID = '851725313390' // **REPLACE THIS** with your AWS Account ID
        
        // ECR Repository details
        IMAGE_REPO_NAME = 'locastitch' // **REPLACE THIS** with your ECR Repository Name
        
        // Jenkins Credentials ID
        AWS_CREDENTIALS_ID = 'aws-dev-env' // **REPLACE THIS** with the ID you gave your AWS Credentials in Jenkins
        
        // Final image URI (using Jenkins' internal build number as a unique tag)
        IMAGE_TAG = "build-${env.BUILD_NUMBER}"
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_URI = "${ECR_REGISTRY}/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
    }

    // 2. AGENT (where the work runs)
    // We use the Docker executable installed on the Jenkins server (or agent)
    agent any

    // 3. STAGES
    stages {
        
        // STAGE 1: Build the Docker Image
        stage('Build Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_URI}"
                    // Build the Docker image using the Dockerfile in the current directory
                    docker.build IMAGE_URI 
                }
            }
        }
        
        // STAGE 2: Push the Image to AWS ECR
        stage('Push to ECR') {
            steps {
                // This block uses the AWS Credentials defined in Jenkins
                withAWS(region: AWS_REGION, credentials: AWS_CREDENTIALS_ID) {
                    sh """
                    # 1. Get ECR login token and pipe it to docker login
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    
                    # 2. Push the image
                    echo "Pushing Docker image: ${IMAGE_URI}"
                    docker push ${IMAGE_URI}
                    """
                }
            }
        }
        
        // STAGE 3: Deploy to ECS (Continuous Deployment)
        stage('Deploy to ECS') {
            steps {
                withAWS(region: AWS_REGION, credentials: AWS_CREDENTIALS_ID) {
                    sh """
                    # Configuration (REPLACE THESE WITH YOUR ACTUAL ECS NAMES)
                    TASK_DEFINITION_NAME="locastitch-task-def"
                    CLUSTER_NAME="locastitch-cluster"
                    SERVICE_NAME="locastitch-service"
                    
                    # 1. Get the current active Task Definition ARN
                    echo "Getting current Task Definition for service \${SERVICE_NAME}..."
                    CURRENT_TASK_DEF_ARN=\$(aws ecs describe-services --cluster \${CLUSTER_NAME} --services \${SERVICE_NAME} --query "services[0].taskDefinition" --output text)
                    
                    # 2. Get the full JSON of the current Task Definition, removing transient fields
                    echo "Retrieving and cleaning Task Definition JSON..."
                    TASK_DEF_JSON=\$(aws ecs describe-task-definition --task-definition \${CURRENT_TASK_DEF_ARN} --query "taskDefinition" | jq 'del(.status, .registeredAt, .deregisteredAt, .registeredBy, .compatibilities, .requiresAttributes, .taskDefinitionArn, .revision, .requiresCompatibilities)')
                    
                    # 3. Update the image tag in the JSON using jq
                    echo "Updating image URI to ${IMAGE_URI} in the JSON..."
                    NEW_TASK_DEF_JSON=\$(echo \${TASK_DEF_JSON} | jq --arg image "${IMAGE_URI}" '.containerDefinitions[0].image = \$image')
                    
                    # *** FIX HERE: Write JSON to a temporary file before registering ***
                    echo "Writing new Task Definition JSON to temporary file..."
                    echo \${NEW_TASK_DEF_JSON} > new-task-definition.json
                    
                    # 4. Register the new Task Definition using the temporary file
                    echo "Registering a new Task Definition revision using file input..."
                    NEW_TASK_DEF_ARN=\$(aws ecs register-task-definition --cli-input-json file://new-task-definition.json --output text --query "taskDefinition.taskDefinitionArn")
                    
                    # 5. Update the ECS Service to use the new Task Definition
                    echo "Updating ECS service \${SERVICE_NAME} to use new Task Definition: \${NEW_TASK_DEF_ARN}"
                    aws ecs update-service \\
                        --cluster \${CLUSTER_NAME} \\
                        --service \${SERVICE_NAME} \\
                        --task-definition \${NEW_TASK_DEF_ARN} \\
                        --force-new-deployment
                    """
                }
            }
        }
    }
}
