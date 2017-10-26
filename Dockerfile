FROM gcr.io/tensorflow/tensorflow:1.3.0-gpu-py3 

RUN mkdir -p /notebooks/TF-examples && \
	mv /notebooks/*.ipynb /notebooks/TF-examples 
RUN mkdir -p /notebooks/Keras-examples
COPY Keras-examples/examples /notebooks/Keras-examples

RUN mkdir -p /notebooks/DL_Training_materials
COPY 1 Image Recognition 2 Text Classification /notebooks/DL_Training_materials

RUN apt-get update && apt-get install -y --no-install-recommends \
	git \
	wget \
	vim \
	inetutils-ping \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip --no-cache-dir install scikit-learn nltk openpyxl seaborn pandas gensim imbalanced-learn Keras h5py Keras many_stop_words regex folium bokeh branca xlrd fiona tqdm autopep8 https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master jupyter_nbextensions_configurator

RUN jupyter contrib nbextension install --user --skip-running-check && jupyter nbextensions_configurator enable --user 



# Set shell to bash
ENV SHELL /bin/bash

#WORKDIR /notebooks
#CMD ["/run_jupyter.sh"]
