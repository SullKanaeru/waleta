import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('76.13.17.86', username='developer', password='dev123')

script = "SELECT id, name, total_allocated FROM master_envelopes;"
stdin, stdout, stderr = ssh.exec_command(f'docker exec waleta_db psql -U waleta_user -d waleta_db -c "{script}"')
print("STDOUT:", stdout.read().decode())
print("STDERR:", stderr.read().decode())
ssh.close()
