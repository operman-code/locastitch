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
        
        // STAGE 3: Deploy (This will be the next step after ECR)
        stage('Deploy to ECS') {
            steps {
                echo "Deployment stage is placeholder. Next, we will use AWS CLI or a plugin to update the ECS service."
            }
        }
    }
}
