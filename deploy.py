import paramiko
from scp import SCPClient
import os
import shutil
import zipfile

def create_zip(source_dir, output_filename):
    with zipfile.ZipFile(output_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, source_dir)
                zipf.write(file_path, arcname)

def deploy():
    print("Zipping backend...")
    create_zip('d:\\Waleta\\be', 'backend.zip')

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    print("Connecting to VPS...")
    ssh.connect('76.13.17.86', username='developer', password='dev123')
    
    print("Uploading backend.zip...")
    with SCPClient(ssh.get_transport()) as scp:
        scp.put('backend.zip', '/home/developer/backend.zip')
        
    print("Extracting and running docker-compose...")
    commands = [
        "rm -rf /home/developer/be",
        "unzip -o /home/developer/backend.zip -d /home/developer/be",
        "cd /home/developer/be && docker compose down || true",
        "cd /home/developer/be && docker compose up -d --build"
    ]
    
    for cmd in commands:
        stdin, stdout, stderr = ssh.exec_command(cmd)
        exit_status = stdout.channel.recv_exit_status()
        print(f"[{cmd}] Exit status: {exit_status}")
        print(stdout.read().decode())
        print(stderr.read().decode())

    ssh.close()
    print("Deployment completed!")

if __name__ == '__main__':
    deploy()
