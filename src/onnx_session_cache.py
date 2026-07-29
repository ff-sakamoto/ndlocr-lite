import os
import onnxruntime


def _get_cache_dir() -> str:
    appdata = os.environ.get("APPDATA") or os.path.expanduser("~")
    return os.path.join(appdata, "fanfare", "HybridOCR", ".onnx_cache")


def create_cached_session(model_path: str, opt_session: onnxruntime.SessionOptions,
                           providers: list, device: str) -> onnxruntime.InferenceSession:
    """%APPDATA%\\fanfare\\HybridOCR\\.onnx_cache にグラフ最適化済みモデルをキャッシュし、
    2回目以降のロードでは最適化パスを省略して高速化する。
    キャッシュの読み書きに失敗した場合は通常ロードにフォールバックする。
    """
    try:
        cache_dir = _get_cache_dir()
        stem = os.path.splitext(os.path.basename(model_path))[0]
        cache_path = os.path.join(cache_dir, f"{stem}.{device.casefold()}.optimized.onnx")

        if os.path.isfile(cache_path) and os.path.getmtime(cache_path) >= os.path.getmtime(model_path):
            disable_opt = onnxruntime.SessionOptions()
            disable_opt.graph_optimization_level = onnxruntime.GraphOptimizationLevel.ORT_DISABLE_ALL
            disable_opt.intra_op_num_threads = opt_session.intra_op_num_threads
            disable_opt.inter_op_num_threads = opt_session.inter_op_num_threads
            return onnxruntime.InferenceSession(cache_path, disable_opt, providers=providers)

        os.makedirs(cache_dir, exist_ok=True)
        opt_session.optimized_model_filepath = cache_path
        return onnxruntime.InferenceSession(model_path, opt_session, providers=providers)
    except Exception:
        return onnxruntime.InferenceSession(model_path, opt_session, providers=providers)
