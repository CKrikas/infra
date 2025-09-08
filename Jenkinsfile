pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('Checkout infra') { steps { checkout scm } }

    stage('Install Ansible (venv)') {
      steps {
        sh '''
          set -eux
          python3 -m venv .venv
          . .venv/bin/activate
          pip install --upgrade pip
          pip install "ansible>=9,<10"
        '''
      }
    }

    stage('Deploy with Ansible') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'vm-ssh', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'ghcr_pat', variable: 'GHCR_TOKEN')   // <-- use your actual ID (e.g. ghcr-token)
        ]) {
          sh '''
            set -eux
            export ANSIBLE_HOST_KEY_CHECKING=false
            . .venv/bin/activate
            ansible-playbook -i ansible/hosts.ini ansible/site-docker.yml \
              --private-key "$SSH_KEY" \
              -e "ghcr_token=${GHCR_TOKEN}"
          '''
        }
      }
    }
  }
}
