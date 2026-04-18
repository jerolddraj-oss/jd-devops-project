pipeline {
    agent { label 'windows-agent-1' }

    environment {
        TF_DIR = "terraform"
        ANSIBLE_DIR = "ansible"
        KEYVAULT_NAME = "jd-keyvault"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/jerolddraj-oss/jd-devops-project.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Get VM IP') {
            steps {
                script {
                    VM_IP = sh(
                        script: "cd terraform && terraform output -raw vm_private_ip",
                        returnStdout: true
                    ).trim()
                    echo "VM IP: ${VM_IP}"
                }
            }
        }

        stage('Fetch Credentials from Key Vault') {
            steps {
                script {
                    VM_USER = sh(
                        script: "az keyvault secret show --vault-name ${KEYVAULT_NAME} --name vm-username --query value -o tsv",
                        returnStdout: true
                    ).trim()

                    VM_PASS = sh(
                        script: "az keyvault secret show --vault-name ${KEYVAULT_NAME} --name vm-password --query value -o tsv",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Create Ansible Inventory') {
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
            steps {
                dir("${ANSIBLE_DIR}") {
                    sh 'ansible-playbook -i inventory.ini iis.yml'
                }
            }
        }
    }
}