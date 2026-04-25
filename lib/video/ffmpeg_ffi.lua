local ffi = require("ffi")

local M = {}

-- Load DLLs in dependency order (avutil first, then codecs, then format/scale)
local dynlib = "dynlib/"
if ffi.os == "Linux" then
    M.avutil     = ffi.load(dynlib .. "libavutil.so")
    M.swresample = ffi.load(dynlib .. "libswresample.so")
    M.avcodec    = ffi.load(dynlib .. "libavcodec.so")
    M.avformat   = ffi.load(dynlib .. "libavformat.so")
    M.swscale    = ffi.load(dynlib .. "libswscale.so")
elseif ffi.os == "OSX" then
    M.avutil     = ffi.load(dynlib .. "libavutil.dylib")
    M.swresample = ffi.load(dynlib .. "libswresample.dylib")
    M.avcodec    = ffi.load(dynlib .. "libavcodec.dylib")
    M.avformat   = ffi.load(dynlib .. "libavformat.dylib")
    M.swscale    = ffi.load(dynlib .. "libswscale.dylib")
else
    M.avutil     = ffi.load(dynlib .. "avutil-60")
    M.swresample = ffi.load(dynlib .. "swresample-6")
    M.avcodec    = ffi.load(dynlib .. "avcodec-62")
    M.avformat   = ffi.load(dynlib .. "avformat-62")
    M.swscale    = ffi.load(dynlib .. "swscale-9")
end

-- Struct definitions (FFmpeg 7.x / avutil-60, avcodec-62, avformat-62)
ffi.cdef[[
    // --- Primitives ---
    typedef struct { int num; int den; } AVRational;

    // --- Opaque types ---
    typedef struct AVCodecContext AVCodecContext;
    typedef struct AVCodec AVCodec;
    typedef struct SwsContext SwsContext;

    // --- AVCodecParameters (fields up to width/height) ---
    typedef struct AVCodecParameters {
        int          codec_type;           // enum AVMediaType
        int          codec_id;             // enum AVCodecID
        uint32_t     codec_tag;
        int          _pad0;
        uint8_t     *extradata;
        int          extradata_size;
        int          _pad1;
        void        *coded_side_data;
        int          nb_coded_side_data;
        int          format;
        int64_t      bit_rate;
        int          bits_per_coded_sample;
        int          bits_per_raw_sample;
        int          profile;
        int          level;
        int          width;
        int          height;
    } AVCodecParameters;

    // --- AVStream (fields up to nb_frames) ---
    typedef struct AVStream {
        const void          *av_class;
        int                  index;
        int                  id;
        AVCodecParameters   *codecpar;
        void                *priv_data;
        AVRational           time_base;
        int64_t              start_time;
        int64_t              duration;
        int64_t              nb_frames;
    } AVStream;

    // --- AVFormatContext (fields up to duration) ---
    typedef struct AVFormatContext {
        const void   *av_class;
        const void   *iformat;
        const void   *oformat;
        void         *priv_data;
        void         *pb;
        int           ctx_flags;
        unsigned int  nb_streams;
        AVStream    **streams;
        char         *url;
        int64_t       start_time;
        int64_t       duration;
    } AVFormatContext;

    // --- AVPacket (fields up to stream_index) ---
    typedef struct AVPacket {
        void        *buf;
        int64_t      pts;
        int64_t      dts;
        uint8_t     *data;
        int          size;
        int          stream_index;
        int          flags;
    } AVPacket;

    // --- AVFrame (FFmpeg 7.x layout — key_frame removed) ---
    typedef struct AVFrame {
        uint8_t     *data[8];
        int          linesize[8];
        uint8_t    **extended_data;
        int          width;
        int          height;
        int          nb_samples;
        int          format;
        int          pict_type;
        int          _pad0;
        AVRational   sample_aspect_ratio;
        int64_t      pts;
    } AVFrame;

    // --- avformat functions ---
    int           avformat_open_input(AVFormatContext **ps, const char *url, const void *fmt, void **options);
    int           avformat_find_stream_info(AVFormatContext *ic, void **options);
    void          avformat_close_input(AVFormatContext **s);
    int           av_find_best_stream(AVFormatContext *ic, int type, int wanted_stream_nb, int related_stream, const AVCodec **decoder_ret, int flags);
    int           av_read_frame(AVFormatContext *s, AVPacket *pkt);
    int           av_seek_frame(AVFormatContext *s, int stream_index, int64_t timestamp, int flags);

    // --- avcodec functions (includes packet API) ---
    const AVCodec      *avcodec_find_decoder(int id);
    AVCodecContext     *avcodec_alloc_context3(const AVCodec *codec);
    void                avcodec_free_context(AVCodecContext **avctx);
    int                 avcodec_parameters_to_context(AVCodecContext *codec, const AVCodecParameters *par);
    int                 avcodec_open2(AVCodecContext *avctx, const AVCodec *codec, void **options);
    int                 avcodec_send_packet(AVCodecContext *avctx, const AVPacket *avpkt);
    int                 avcodec_receive_frame(AVCodecContext *avctx, AVFrame *frame);
    void                avcodec_flush_buffers(AVCodecContext *avctx);
    AVPacket           *av_packet_alloc(void);
    void                av_packet_free(AVPacket **pkt);
    void                av_packet_unref(AVPacket *pkt);

    // --- avutil functions ---
    AVFrame            *av_frame_alloc(void);
    void                av_frame_free(AVFrame **frame);
    void                av_frame_unref(AVFrame *frame);
    int64_t             av_rescale_q(int64_t a, AVRational bq, AVRational cq);
    void                av_log_set_level(int level);
    int                 av_opt_set(void *obj, const char *name, const char *val, int search_flags);
    int                 av_opt_get_int(void *obj, const char *name, int search_flags, int64_t *out_val);

    // --- swscale functions ---
    SwsContext         *sws_getContext(int srcW, int srcH, int srcFormat,
                                       int dstW, int dstH, int dstFormat,
                                       int flags, void *srcFilter, void *dstFilter, const double *param);
    int                 sws_scale(SwsContext *c,
                                  const uint8_t *const srcSlice[], const int srcStride[],
                                  int srcSliceY, int srcSliceH,
                                  uint8_t *const dst[], const int dstStride[]);
    void                sws_freeContext(SwsContext *swsContext);
]]

-- Constants
M.AVMEDIA_TYPE_VIDEO   = 0
M.AV_PIX_FMT_RGBA     = 26
M.SWS_BILINEAR        = 2
M.AVSEEK_FLAG_BACKWARD = 1
M.AVERROR_EOF          = -541478725   -- FFERRTAG('E','O','F',' ')
M.AVERROR_EAGAIN       = -11          -- AVERROR(EAGAIN)
M.AV_TIME_BASE         = 1000000     -- microseconds
M.AV_NOPTS_VALUE       = 0x8000000000000000LL
M.AV_LOG_FATAL         = 8
M.AV_LOG_ERROR         = 16
M.AV_LOG_WARNING       = 24
M.AV_LOG_QUIET         = -8

return M
