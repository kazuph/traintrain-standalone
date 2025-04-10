FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
# ユーザー設定に合わせてGradioの設定を環境変数で定義
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7861

# システムパッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  python3.10 \
  python3.10-venv \
  python3-pip \
  python3-dev \
  build-essential \
  libgl1-mesa-glx \
  libglib2.0-0 \
  libsm6 \
  libxext6 \
  libxrender-dev \
  ffmpeg \
  wget \
  curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# 作業ディレクトリの作成
WORKDIR /app

# 必要なディレクトリを作成
RUN mkdir -p /app/models /app/outputs

# Pythonの仮想環境を設定
ENV PATH="/app/venv/bin:$PATH"
RUN python3.10 -m venv /app/venv

# Python依存関係のインストール
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
ENV TORCH_INDEX_URL=https://download.pytorch.org/whl/cu121
RUN pip install --no-cache-dir torch==2.3.1 torchvision==0.18.1 --extra-index-url ${TORCH_INDEX_URL}

# その他の依存関係のインストール
RUN pip install --no-cache-dir pandas numpy scikit-learn scipy matplotlib
RUN pip install --no-cache-dir opencv-python-headless pillow
RUN pip install --no-cache-dir xformers==0.0.27
RUN pip install --no-cache-dir gradio==3.41.2
RUN pip install --no-cache-dir accelerate transformers diffusers

# TrainTrainの依存関係
RUN pip install --no-cache-dir https://github.com/openai/CLIP/archive/d50d76daa670286dd6cacf3bcd80b5e4823fc8e1.zip
RUN pip install --no-cache-dir https://github.com/mlfoundations/open_clip/archive/bb6e834e9c70d9c27d0dc3ecedeebeaeb1ffad6b.zip
RUN pip install --no-cache-dir pytorch-optimizer==3.5.0

# プロジェクトファイルをコピー
COPY . /app/

# 実行権限を付与
RUN chmod +x /app/webui.sh /app/webui-user.sh

# ポートを公開
EXPOSE 7861

# 起動コマンド - ユーザーが使用しているコマンドに合わせる
CMD ["bash", "webui-user.sh", "--models-dir", "/app/models", "--ckpt-dir", "/app/models", "--lora-dir", "/app/outputs", "--xformers", "--listen"]
