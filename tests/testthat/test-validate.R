library(tableschema.r)
library(testthat)

context("validate")

# Fixtures

SCHEMA <- '{
  "fields": [
    {"name": "id", "type": "string", "constraints": { "required": true }},
    {"name": "height", "type": "number"},
    {"name": "age", "type": "integer"},
    {"name": "name", "type": "string", "constraints": {"required": true}},
    {"name": "occupation", "type": "string"}
    ],
  "primaryKey": ["id"]
}'



# Tests

test_that("ensure schema has fields", {
  validation <- tableschema.r::validate('[]')
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("ensure schema has fields and fields are array", {
  validation <- tableschema.r::validate('{"fields": ["1", "2"]}')
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 2L)
})

test_that("ensure schema fields has required properties", {
  schema <- '{"fields": [{"name": "id"}, {"type": "number"}]}'
  validation <- tableschema.r::validate(schema)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})


test_that("ensure schema fields constraints must be an object", {
  schema <- '{"fields": [{"name": "id", "constraints": "string"}]}'
  validation <- tableschema.r::validate(schema)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("ensure constraints properties have correct type", {
  descriptor <- '{
                  	"fields": [{
	                	"name": "age",
                		"type": "integer",
		                "constraints": {
                  			"required": "string",
                  			"unique": "string",
                  			"minLength": true,
                  			"maxLength": true,
                  			"minimum": "string",
                  			"maximum": "string"
	                	}
            	    }]
                 }'
  
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
  })

test_that("ensure constraints properties with correct type is valid", {
  descriptor <- '{
                  	"fields": [{
                  			"name": "id",
                  			"type": "string",
                  			"constraints": {
                  				"required": true,
                  				"pattern": "/.*/",
                  				"unique": true
                  			}
                  		}, {
                  			"name": "age",
                  			"type": "integer",
                  			"constraints": {
                  				"required": true,
                  				"unique": true,
                  				"minimum": "10",
                  				"maximum": "20"
                  			}
                  		}]
                  	}'
  
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, TRUE)
  expect_equal(length(validation$errors), 0)
})

test_that("primary key should be by type one of the allowed by schema", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$primaryKey <- list(some = 'thing')
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("primary key should match field names", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$primaryKey <- list('unknown')
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("ensure primary key as array match field names", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$primaryKey <- list('id','unknown')
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("ensure foreign keys is an array", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- 'keys'
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("ensure every foreign key has fields", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- list('key1', 'key2')
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 2L)
})

test_that("ensure fields in keys a string or an array", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- list(list(fields = list(name = "id")))
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 1L)
})

test_that("ensure fields exists in schema", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- helpers.from.json.to.list(
    '[{
	    	"fields": ["unknown"],
	    	"reference": {
	  		"fields": ["fk_id"],
	  		"resource": "resource"
     		}
    	},
    	{
    		"fields": ["id", "unknown"],
    		"reference": {
    			"resource": "the-resource",
    			"fields": ["fk_id", "fk_name"]
    		}
    	}
    ]')
  
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 2L)
})

test_that("reference.fields should be same type as key.fields", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- helpers.from.json.to.list(
    '[
        {
            "fields": ["id"],
            "reference": {"fields": ["id", "name"], "resource": "resource"}
        },
        {
            "fields": ["id", "name"],
            "reference": {"resource": "resource", "fields": ["id"]}
        },
        {
            "fields": ["id", "name"],
            "reference": {"resource": "resource", "fields": ["id"]}
        }
    ]'
  )
  
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 3L)
})

test_that("fields in keys a string or an array and resource is present", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- helpers.from.json.to.list(
    '[{
      		"fields": ["id"],
      		"reference": {
      			"fields": ["fk_id"],
      			"resource": "resource"
      		}
      	},
      	{
      		"fields": ["id", "name"],
      		"reference": {
      			"resource": "the-resource",
      			"fields": ["fk_id", "fk_name"]
      		}
      	}
      ]')
  
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 2)
})

test_that("empty resource should reference to the self fields", {
  descriptor <- helpers.from.json.to.list(SCHEMA)
  descriptor$foreignKeys <- helpers.from.json.to.list(
    '[{
    		"fields": ["id"],
	    	"reference": {
		    	"fields": ["fk_id"],
    			"resource": ""
	    	}
    	},
    	{
    		"fields": ["id", "name"],
    		"reference": {
	    		"resource": "",
		    	"fields": ["fk_id", "fk_name"]
    		}
    	}
    ]'
  )
  
  descriptor <- helpers.from.list.to.json(descriptor)
  validation <- tableschema.r::validate(descriptor)
  expect_equal(validation$valid, FALSE)
  expect_equal(length(validation$errors), 4)
})

test_that("should support local descriptors", {
  
  validation <- tableschema.r::validate(readLines('inst/extdata/schema.json'))
  expect_equal(validation$valid, TRUE)
  expect_equal(length(validation$errors), 0)
})
