# S3_storage

S3 Bucket Storage Management

## Required Environment Variables

|                     |     |
| ------------------- | --- |
| `BUCKET_NAME`       | Bucket Name                  |
| `BUCKET_REGION`     | Bucket Region (e.g., `atl1`) |
| `BUCKET_KEY_ID`     | Bucket Access Key ID         |
| `BUCKET_KEY_SECRET` | Bucket Secret Access Key     |
| `DEV_WHATSAPP_NUMBER` | Optional: Dev WhatsApp number for use in `clear_user.py` |

## Scripts

Download every object under an S3 prefix:

```bash
./download_prefix.py <prefix> [ Optional: <output_dir> ]
```

If `output_dir` is omitted, files are saved under `downloads/<prefix>/`.
