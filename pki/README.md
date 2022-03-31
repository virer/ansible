
Local usage
  ansible-playbook -i localhost, pki.yml --connection=local


Usage example whe you already generate the CA
  ansible-playbook -i 10.108.193.122, -u root --skip-tags ca pki.yml