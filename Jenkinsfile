pipeline {
  agent {
    docker {
      image 'python:3.12-slim'
      // run as root so we can apt-get a couple tiny tools
      args '-u root'
    }
  }
  options { timestamps() }

  stages {
    stage('Checkout infra') { steps { checkout scm } }

    stage('Setup tools') {
      steps {
        sh '''
          set -eux
          apt-get update
          apt-get install -y --no-install-recommends git openssh-client
          pip install --no-cache-dir --upgrade pip
          pip install --no-cache-dir "ansible>=9,<10"
        '''
      }
    }

    stage('Deploy with Ansible') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'vm-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'ghcr_pat', variable: 'GHCR_TOKEN')  // <- or your actual ID
        ]) {
          sh '''
            set -eux
            export ANSIBLE_HOST_KEY_CHECKING=false
            ansible-playbook -i ansible/hosts.ini ansible/site-docker.yml \
              --private-key "$SSH_KEY" \
              -e "ghcr_token=${GHCR_TOKEN}"
          '''
        }
      }
    }
  }
}
