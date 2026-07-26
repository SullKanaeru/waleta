import paramiko

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('76.13.17.86', username='developer', password='dev123')

script = """
WITH ranked AS (
    SELECT id, name, ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) as rn
    FROM master_envelopes
)
DELETE FROM master_envelopes WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

UPDATE master_envelopes SET user_id = '70529128-636b-4c4c-a513-99d44b025047' WHERE user_id IS NULL OR user_id = '';
"""

stdin, stdout, stderr = ssh.exec_command(f'docker exec waleta_db psql -U waleta_user -d waleta_db -c "{script}"')
print("STDOUT:", stdout.read().decode())
print("STDERR:", stderr.read().decode())
ssh.close()
