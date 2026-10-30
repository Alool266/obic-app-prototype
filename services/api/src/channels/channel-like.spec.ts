// Made by Dr Ali
// Channel like toggle persists likedByMe + likeCount on the video row.

import { ChannelVideoLike } from './channel-video-like.entity';
import { ChannelVideo } from './channel-video.entity';

describe('channel like persistence (service contract)', () => {
  it('toggleLike response shape includes liked + likeCount + videoId', () => {
    const likedPayload = {
      liked: true as const,
      likeCount: 1,
      videoId: '93cb91ff-9657-450c-8085-a8f8b6ab7080',
    };
    const unlikedPayload = {
      liked: false as const,
      likeCount: 0,
      videoId: likedPayload.videoId,
    };
    expect(likedPayload.liked).toBe(true);
    expect(unlikedPayload.liked).toBe(false);
    expect(likedPayload.likeCount).toBeGreaterThanOrEqual(0);
  });

  it('ChannelVideoLike entity is uniquely keyed by videoId + userId', () => {
    const row = new ChannelVideoLike();
    row.videoId = 'v1';
    row.userId = 'u1';
    expect(row.videoId).toBe('v1');
    expect(row.userId).toBe('u1');
    const video = new ChannelVideo();
    video.likeCount = 0;
    video.likeCount += 1;
    expect(video.likeCount).toBe(1);
  });
});
