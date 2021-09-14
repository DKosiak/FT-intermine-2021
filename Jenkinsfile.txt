pipeline {
  environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
  }
  
  agent  any
  
  stages {
      stage('fetch_latest_code') {
        steps {
          git credentialsId: 'GitHub', url: 'https://github.com/DKosiak/FT-intermine-2021.git'
        }
      }
	  
	  stage('TF Init and Plan') {
	    steps {
          sh 'terraform init'
          sh 'terraform plan -out=create.tfplan'
        }      
      }
	  
	  stage ('Terraform Apply') {
        steps {
 		  sh 'terraform apply -no-color -auto-approve create.tfplan'
        }
	  }	
    }
}
