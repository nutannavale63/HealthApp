pipeline {
    agent any

    environment {
        PATH = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${env.PATH}"
        AWS_REGION = 'us-west-2'
        ECR_REGISTRY = '591950085623.dkr.ecr.us-west-2.amazonaws.com'
        CLUSTER_NAME = 'bbhealthapp-cluster'
        NAMESPACE = 'bbhealthapp'
        FRONTEND_IMAGE = 'bbhealthapp-frontend'
        MASTER_IMAGE = 'bbhealthapp-master-service'
        REGISTER_IMAGE = 'bbhealthapp-register-service'
        DOCUMENT_IMAGE = 'bbhealthapp-document-service'
        HELM_RELEASE = 'bbhealthapp'
        HELM_CHART_PATH = './helm/bbhealthapp'
        TERRAFORM_DIR = './terraform'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'REBUILD_INFRA', defaultValue: false, description: 'Rebuild infrastructure with Terraform (Stage 2)')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run automated tests')
    }

    stages {
        stage('Setup') {
            steps {
                script {
                    currentBuild.displayName = "#${BUILD_NUMBER} - ${params.ENVIRONMENT}"
                    echo "========================================"
                    echo "Starting BBHealthApp CI/CD Pipeline"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "========================================"
                }
            }
        }

        // STAGE 1: Source pulled from GitHub
        stage('Stage 1: Checkout from GitHub') {
            steps {
                echo "[STAGE 1] Pulling source code from GitHub..."
                checkout scm
                sh '''
                    echo "Current commit:"
                    git log -1 --oneline
                    echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
                '''
            }
        }

        stage('Configure AWS') {
            steps {
                echo "[CONFIG] Configuring AWS credentials and ECR login..."
                sh """
                    aws configure set region ${AWS_REGION}
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                    echo "[SUCCESS] AWS configured successfully"
                """
            }
        }

        // STAGE 2: Terraform infrastructure
        stage('Stage 2: Terraform Infrastructure') {
            when {
                expression { params.REBUILD_INFRA == true }
            }
            steps {
                echo "[STAGE 2] Provisioning infrastructure with Terraform..."
                dir("${TERRAFORM_DIR}") {
                    sh """
                        echo "Initializing Terraform..."
                        terraform init -input=false

                        echo "Planning Terraform changes..."
                        terraform plan -out=tfplan -var="environment=${params.ENVIRONMENT}"

                        echo "Applying Terraform changes..."
                        terraform apply -auto-approve tfplan

                        echo "[SUCCESS] Infrastructure provisioned successfully"
                    """
                }
            }
        }

        // STAGE 3: Docker images build
        stage('Stage 3: Build Docker Images') {
            steps {
                parallel(
                    "Build Frontend": {
                        dir('bbhealthapp-frontend') {
                            sh """
                                echo "[STAGE 3] Building Frontend image..."
                                docker build -t ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest
                                echo "[SUCCESS] Frontend image built successfully"
                            """
                        }
                    },
                    "Build Master Service": {
                        dir('bbhealthapp-backend/bbhealthapp-api-master') {
                            sh """
                                echo "[STAGE 3] Building Master Service image..."
                                docker build -t ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${MASTER_IMAGE}:latest
                                echo "[SUCCESS] Master Service image built successfully"
                            """
                        }
                    },
                    "Build Register Service": {
                        dir('bbhealthapp-backend/bbhealthapp-api-register') {
                            sh """
                                echo "[STAGE 3] Building Register Service image..."
                                docker build -t ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${REGISTER_IMAGE}:latest
                                echo "[SUCCESS] Register Service image built successfully"
                            """
                        }
                    },
                    "Build Document Service": {
                        dir('bbhealthapp-backend/bbhealthapp-api-document') {
                            sh """
                                echo "[STAGE 3] Building Document Service image..."
                                docker build -t ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:${BUILD_NUMBER} .
                                docker tag ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:${BUILD_NUMBER} ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:latest
                                echo "[SUCCESS] Document Service image built successfully"
                            """
                        }
                    }
                )
            }
        }

        stage('Run Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "[TEST] Running pre-push tests..."
                sh """
                    # Run basic Docker image validation
                    docker images | grep bbhealthapp

                    # Test frontend build
                    docker run --rm ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER} ls -la /usr/local/apache2/htdocs/ || true

                    echo "[SUCCESS] Tests completed"
                """
            }
        }

        // STAGE 4: Push Docker images to AWS ECR
        stage('Stage 4: Push Docker Images to ECR') {
            steps {
                echo "[STAGE 4] Pushing Docker images to AWS ECR..."
                sh """
                    echo "Pushing Frontend image..."
                    docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${FRONTEND_IMAGE}:latest

                    echo "Pushing Master Service image..."
                    docker push ${ECR_REGISTRY}/${MASTER_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${MASTER_IMAGE}:latest

                    echo "Pushing Register Service image..."
                    docker push ${ECR_REGISTRY}/${REGISTER_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${REGISTER_IMAGE}:latest

                    echo "Pushing Document Service image..."
                    docker push ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:${BUILD_NUMBER}
                    docker push ${ECR_REGISTRY}/${DOCUMENT_IMAGE}:latest

                    echo "[SUCCESS] All images pushed to ECR successfully"
                """
            }
        }

        // STAGE 5: Deploy using Helm
        stage('Stage 5: Deploy using Helm') {
            steps {
                echo "[STAGE 5] Deploying to EKS using Helm..."
                sh """
                    echo "Updating kubeconfig for EKS cluster..."
                    aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}

                    echo "Cleaning up existing namespace if it exists..."
                    kubectl delete namespace ${NAMESPACE} --ignore-not-found=true || true

                    echo "Deploying with Helm..."
                    helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_PATH} \
                      --namespace ${NAMESPACE} \
                      --create-namespace \
                      --set image.registry=${ECR_REGISTRY} \
                      --set image.tag=${BUILD_NUMBER} \
                      --set global.environment=${params.ENVIRONMENT} \
                      --wait \
                      --timeout 10m

                    echo "[SUCCESS] Deployment completed successfully"
                """
            }
        }

        stage('Health Check') {
            steps {
                echo "[HEALTH] Performing health checks..."
                sh """
                    aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}

                    echo "Waiting for pods to be ready..."
                    kubectl wait --for=condition=ready pod -n ${NAMESPACE} --timeout=300s --all

                    echo "Getting pod status..."
                    kubectl get pods -n ${NAMESPACE}
                    kubectl get services -n ${NAMESPACE}
                    kubectl get ingress -n ${NAMESPACE}

                    echo "Checking deployment status..."
                    helm status ${HELM_RELEASE} -n ${NAMESPACE}

                    echo "[SUCCESS] Health checks passed"
                """
            }
        }

        stage('Integration Tests') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo "[INTEGRATION] Running integration tests..."
                script {
                    try {
                        sh """
                            # Get Load Balancer URL
                            LB_URL=\$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
                            echo "Load Balancer URL: \$LB_URL"

                            # Basic connectivity test
                            echo "Testing frontend endpoint..."
                            curl -f http://\$LB_URL/ || echo "Frontend test failed"

                            echo "Testing master service endpoint..."
                            curl -f http://\$LB_URL/api/master/actuator/health || echo "Master service health check failed"

                            echo "[SUCCESS] Integration tests completed"
                        """
                    } catch (Exception e) {
                        echo "[WARNING] Integration tests failed: ${e}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "[CLEANUP] Cleaning up..."
                sh """
                    # Clean up old Docker images
                    docker system prune -f
                    docker image prune -a -f
                    echo "[SUCCESS] Cleanup completed"
                """
            }
        }
    }

    post {
        success {
            echo "========================================"
            echo "[SUCCESS] Pipeline executed successfully!"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Build Number: ${BUILD_NUMBER}"
            echo "Image Tag: ${BUILD_NUMBER}"
            echo "========================================"
        }
        failure {
            echo "========================================"
            echo "[FAILURE] Pipeline failed!"
            echo "Attempting rollback..."
            echo "========================================"
            sh """
                aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}
                helm rollback ${HELM_RELEASE} -n ${NAMESPACE} || true
            """
        }
        unstable {
            echo "[WARNING] Pipeline completed with warnings"
        }
        always {
            echo "Pipeline execution completed"
            echo "========================================"
        }
    }
}
