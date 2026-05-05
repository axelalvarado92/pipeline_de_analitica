output "glue_crawler_arn" {
  value = aws_glue_crawler.crawler_s3.arn
}

output "glue_database_name" {
    value = aws_glue_catalog_database.pipeline_events_db.name
  
}