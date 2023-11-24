return {
    mongodb_config = {
        db = "game",
        rs = {
            {host = "127.0.0.1",port = 27017,username="game",password="game",authmod="scram_sha1",authdb="admin"},
        },
    }
}