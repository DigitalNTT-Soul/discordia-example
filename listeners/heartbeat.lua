
function handler(shardId, latency)
    
    --// update latency for shard
    client._latency[shardId] = latency

end

self:handle('heartbeat', handler)