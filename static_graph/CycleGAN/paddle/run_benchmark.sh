#!bin/bash
set -xe

if [[ $# -lt 1 ]]; then
    echo "Usage: "
    echo "  CUDA_VISIBLE_DEVICES=0 bash run.sh speed|mem sp|mp /ssd1/ljh/logs"
    exit
fi

function _set_params(){
    index="$1"
    run_mode=${2:-"sp"}
    run_log_path=${3:-$(pwd)}

    model_name="CycleGAN"
    skip_steps=3
    keyword="Batch_time_cost:"
    separator=" "
    position=-1
    model_mode=0

    device=${CUDA_VISIBLE_DEVICES//,/ }
    arr=($device)
    num_gpu_devices=${#arr[*]}
    base_batch_size=1
    log_file=${run_log_path}/${model_name}_${index}_${num_gpu_devices}_${run_mode}
    log_parse_file=${log_file}
}

function _set_env(){
    #打开后速度变快
    export FLAGS_cudnn_exhaustive_search=1
    #显存占用减少，不影响性能
    export FLAGS_eager_delete_tensor_gb=0.0
    export FLAGS_conv_workspace_size_limit=256
}

function _train(){
    echo "Train on ${num_gpu_devices} GPUs"
    echo "current CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES, gpus=$num_gpu_devices, batch_size=${base_batch_size}"
    python train.py > ${log_file} 2>&1 &
    train_pid=$!
    sleep 120
    kill -9 ${train_pid}
}

source ${BENCHMARK_ROOT}/scripts/run_model.sh
_set_params $@
_set_env
_run