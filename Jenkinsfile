pipeline {
    agent none

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Select Terraform action')
    }

    environment {
        TF_DIR = "terraform"
        ANSIBLE_DIR = "ansible"
        KEYVAULT_NAME = "jd-keyvault"
    }

    stages {

        stage('Checkout') {
            agent { label 'windows-agent-1' }
            steps {
                git branch: 'main', url: 'https://github.com/jerolddraj-oss/jd-devops-project.git'
            }
        }

        stage('Terraform Init') {
            agent { label 'windows-agent-1' }
            steps {
                dir("${TF_DIR}") {
                    bat 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent-1' }
            steps {
                dir("${TF_DIR}") {
                    bat 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Approval') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent-1' }
            steps {
                input message: 'Do you want to APPLY Terraform changes?'
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent-1' }
            steps {
                dir("${TF_DIR}") {
                    bat 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Terraform Destroy Approval') {
            when { expression { params.ACTION == 'destroy' } }
            agent { label 'windows-agent-1' }
            steps {
                input message: '⚠️ Do you REALLY want to DESTROY infrastructure?'
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'destroy' } }
            agent { label 'windows-agent-1' }
            steps {
                dir("${TF_DIR}") {
                    bat 'terraform destroy -auto-approve'
                }
            }
        }

        stage('Get VM IP') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent-1' }
            steps {
                script {
                    VM_IP = bat(
                        script: "cd terraform && terraform output -raw vm_private_ip",
                        returnStdout: true
                    ).trim()
                    echo "VM IP: ${VM_IP}"
                }
            }
        }

        stage('Fetch Credentials from Key Vault') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent-1' }
            steps {
                script {
                    VM_USER = bat(
                        script: "az keyvault secret show --vault-name %KEYVAULT_NAME% --name vm-username --query value -o tsv",
                        returnStdout: true
                    ).trim()

                    VM_PASS = bat(
                        script: "az keyvault secret show --vault-name %KEYVAULT_NAME% --name vm-password --query value -o tsv",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Create Ansible Inventory') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent-1' }
            steps {
                script {
                    writeFile file: 'ansible/inventory.ini', text: """
[windows]
${VM_IP}

[windows:vars]
ansible_user=${VM_USER}
ansible_password=${VM_PASS}
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_port=5985
"""
                }
            }
        }

        stage('Run Ansible') {
            when { expression { params.ACTION == 'apply' } }
            agent { label 'windows-agent' }
            steps {
                bat '''
				wsl bash -c "cd /mnt/c/Program\\ Files/Jenkins/workspace/TFandAnsible/ansible && ansible-playbook -i inventory.ini iis.yml"
				'''
                }
            }
        }
    }
}