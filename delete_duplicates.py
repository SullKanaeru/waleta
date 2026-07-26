import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('76.13.17.86', username='developer', password='dev123')

script = """
DELETE FROM master_envelopes WHERE id IN ('df4a7509-24e8-4eba-b6f2-eb80d99d4d27', '8afef58e-d84d-4035-b5c7-ff5b363022ea', 'c0c63ecd-22eb-4140-bcf0-9c2b99be403c');
"""

stdin, stdout, stderr = ssh.exec_command(f'docker exec waleta_db psql -U waleta_user -d waleta_db -c "{script}"')
print("STDOUT:", stdout.read().decode())
print("STDERR:", stderr.read().decode())
ssh.close()
