FROM python:3.9.7 as base

MAINTAINER Eyal Levy eyal@levys.co.il

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1
ENV PATH=/MoniGoMani:/home/ftuser/.local/bin:$PATH
ENV FT_APP_ENV="docker"

WORKDIR /
RUN git clone https://github.com/freqtrade/freqtrade.git
RUN git clone https://github.com/Rikj000/MoniGoMani.git

# Prepare environment
RUN  apt-get update \
  && apt-get -y install sudo libatlas3-base curl sqlite3 libhdf5-serial-dev  \
  && apt-get clean \
  && useradd -u 1000 -G sudo -U -m -s /bin/bash ftuser \
  && chown ftuser:ftuser /freqtrade \
  # Allow sudoers
  && echo "ftuser ALL=(ALL) NOPASSWD: /bin/chown" >> /etc/sudoers

WORKDIR /freqtrade
# Install dependencies
RUN  apt-get update \
  && apt-get -y install build-essential libssl-dev git libffi-dev libgfortran5 pkg-config cmake gcc \
  && apt-get clean \
  && pip install --upgrade pip

# Install TA-lib
WORKDIR /freqtrade/build_helpers
RUN ./install_ta-lib.sh 
ENV LD_LIBRARY_PATH /usr/local/lib

# Install dependencies
WORKDIR /freqtrade
USER ftuser
RUN  pip install --user --no-cache-dir numpy \
  && pip install --user --no-cache-dir -r requirements-hyperopt.txt

# Copy dependencies to runtime-image
ENV LD_LIBRARY_PATH /usr/local/lib

WORKDIR /freqtrade
RUN pip install -e . --user --no-cache-dir --no-build-isolation 

WORKDIR /
USER root
RUN apt install -y expect
#RUN git clone https://github.com/Rikj000/MoniGoMani.git
RUN chown ftuser:ftuser /MoniGoMani

WORKDIR /MoniGoMani
USER ftuser
RUN pip install -r requirements-mgm.txt
COPY installer4docker.sh /MoniGoMani/installer4docker.sh
RUN yes | ./installer4docker.sh
RUN echo alias mgm-hurry='python3 /MoniGoMani/mgm-hurry' > ~/.bashrc


WORKDIR /
USER root
COPY mgm-run.sh /
RUN chmod a+x /mgm-run.sh

ENTRYPOINT [""]
# Default to trade mode
#CMD [ "" ]

