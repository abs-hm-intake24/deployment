import subprocess, os, json, datetime, boto3, argparse


def load_config(name):
    with open(name) as f:
        return json.load(f)


def generate_file_name(target_dir, db_name):
    time = datetime.datetime.now()
    file_name = "{}-snapshot-{}{:02d}{:02d}-{:02d}{:02d}{:02d}.pgcustom".format(db_name, time.year, time.month, time.day,
                                                                              time.hour,
                                                                              time.minute, time.second)
    return os.path.join(target_dir, file_name)


def dump_database(dump_cmd, host, db_name, user, password, output_path):
    env = os.environ.copy()
    env["PGPASSWORD"] = password
    subprocess.run([dump_cmd, "-U", user, "-h", host, "-Fc", "-f", output_path, db_name], env=env, check=True)


def encrypt_file(path, password):
    encrypted_path = path + ".encrypted"
    print("Encrypting database dump as {} ...".format(encrypted_path))
    subprocess.run(["openssl", "aes-256-cbc", "-pass", "pass:" + password, "-in", path, "-out", encrypted_path],
                   check=True)
    return encrypted_path


def upload_to_s3(s3_bucket, s3_name_prefix, path):
    name = s3_name_prefix + os.path.basename(path)

    s3 = boto3.resource("s3")
    s3.Object(s3_bucket, name).put(Body=open(path, 'rb'))


argparser = argparse.ArgumentParser()
argparser.add_argument("config")
args = argparser.parse_args()

config = load_config(args.config)

boto3.setup_default_session(profile_name='intake24-backup')

dump_path = generate_file_name(config["backupDir"], config["database"]["name"])

print("Dumping database to {} ...".format(dump_path))

dump_database(config["dumpCmd"], config["database"]["host"], config["database"]["name"], config["database"]["user"],
              config["database"]["password"], dump_path)

if config["encryption"]["enabled"]:
    encrypted_path = encrypt_file(dump_path, config["encryption"]["password"])
    print("Uploading {} to S3 ...".format(encrypted_path))
    upload_to_s3(config["s3"]["bucket"], config["s3"]["namePrefix"], encrypted_path)
    print(f"Deleting {encrypted_path}, {dump_path} ...")
    os.remove(dump_path)
    os.remove(encrypted_path)
else:
    print("Encryption disabled, skipping")
    print("Uploading {} to S3 ...".format(dump_path))
    upload_to_s3(config["s3"]["bucket"], config["s3"]["namePrefix"], dump_path)
    print(f"Deleting {dump_path} ...")
    os.remove(dump_path)

print("Success!")
