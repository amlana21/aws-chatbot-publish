pipeline{
    agent any
    environment{
        AWS_ACCESS_KEY_ID=credentials('awsaccesskey')
        AWS_SECRET_ACCESS_KEY=credentials('awssecretkey')
        AWS_DEFAULT_REGION="us-east-1"
        SKIP="N"
        TERRADESTROY="N"
        FIRST_DEPLOY="Y"
        INFRA_DEPLOY="Y"
        APP_DEPLOY="Y"
    }

    stages{
        stage("Create Terraform State Buckets"){
            when{
                environment name:'FIRST_DEPLOY',value:'Y'
            }
            steps{
                bat'''
                aws s3 mb s3://<state_bucket_name>'''
            }
        }

        stage("Deploy Infrastructure"){
            when{
                        environment name:'TERRADESTROY',value:'N'
                        environment name:'INFRA_DEPLOY',value:'Y'
                    }
                    stages{
                        stage('Validate Infra'){
                            steps{
                                sh '''
                                cd infra_deploy
                                terraform init
                                terraform validate'''
                            }
                        }
                        stage('Deploy alerts chatbot Infra'){
                            steps{
                                sh '''
                                cd infra_deploy
                                terraform plan -out outfile
                                terraform apply outfile'''
                            }
                        }
                    }  
            
        }

        stage("Deploy Monitoring Lambda"){
            when{
                        environment name:'TERRADESTROY',value:'N'
                        environment name:'APP_DEPLOY',value:'Y'
                        environment name:'FIRST_DEPLOY',value:'Y'
                    }
                    stages{
                        stage('Validate app deploy'){
                            steps{
                                sh '''
                                terraform init
                                terraform validate'''
                            }
                        }
                        stage('Deploy application'){
                            steps{
                                sh '''
                                terraform plan -out outfile
                                terraform apply outfile'''
                            }
                        }
                    }  
            
        }

        stage("Deploy Monitoring Lambda-Update"){
            when{
                        environment name:'TERRADESTROY',value:'N'
                        environment name:'APP_DEPLOY',value:'Y'
                        environment name:'FIRST_DEPLOY',value:'N'
                    }
                    stages{
                        stage('Validate app deploy'){
                            steps{
                                sh '''
                                terraform init
                                terraform validate'''
                            }
                        }
                        stage('Deploy application'){
                            steps{
                                sh '''
                                terraform plan -replace="module.chatbot-alert-lambda.module.lambda_function_local.aws_lambda_function.this[0]" -replace="aws_s3_bucket_object.chatbot_lambda_code" -out outfile
                                terraform apply outfile'''
                            }
                        }
                    }  
            
        }

        stage("Destroy Infra"){
            when{
                environment name:'TERRADESTROY',value:'Y'
            }
            steps{
                sh '''
                    cd infra_deploy
                    terraform destroy -auto-approve
                    aws s3 rb s3://<state_bucket_name> --force'''
            }
            post { 
                always { 
                    cleanWs()
                }
            }
        }
    }


}