import os

# 定义需要转换的文件夹路径
target_dirs = ['./sql']
# 定义需要转换的文件后缀
target_extensions = ['.sql', '.bat']


def convert_file_to_gbk(file_path):
    try:
        # 1. 先尝试用 UTF-8 读取
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 2. 如果读取成功，说明它是 UTF-8，转存为 GBK
        with open(file_path, 'w', encoding='gbk') as f:
            f.write(content)
        print(f"✅ 转换成功: {file_path}")

    except UnicodeDecodeError:
        # 如果 UTF-8 读不出来，说明可能已经是 GBK 或者其他编码，跳过
        print(f"⚠️ 跳过 (可能已是GBK): {file_path}")
    except Exception as e:
        print(f"❌ 出错: {file_path}, 原因: {e}")


def main():
    print("开始批量转换 UTF-8 -> GBK ...")
    for folder in target_dirs:
        if not os.path.exists(folder):
            continue
        # 遍历文件夹
        for root, dirs, files in os.walk(folder):
            for file in files:
                if any(file.endswith(ext) for ext in target_extensions):
                    file_path = os.path.join(root, file)
                    convert_file_to_gbk(file_path)

    # 单独处理根目录下的 bat
    if os.path.exists('setup_db.bat'):
        convert_file_to_gbk('setup_db.bat')

    print("完成！")


if __name__ == '__main__':
    main()