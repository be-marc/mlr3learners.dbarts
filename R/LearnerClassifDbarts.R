#' @title Classification Dbarts Learner
#'
#' @aliases mlr_learners_classif.dbarts
#' @format [R6::R6Class] inheriting from [mlr3::LearnerClassif].
#'
#' @description
#' A [mlr3::LearnerClassif] for a classification dbarts implemented in dbarts::dbarts()] in package \CRANpkg{dbarts}.
#'
# @references
# Breiman, L. (2001).
# Random Forests
# Machine Learning
# \url{https://doi.org/10.1023/A:1010933404324}
#'
#' @export
LearnerClassifDbarts = R6Class("LearnerClassifDbarts", inherit = LearnerClassif, # Adapt the name to your learner. For regression learners inherit = LearnerRegr.
  public = list(
    initialize = function() {
      ps = ParamSet$new( # parameter set using the paradox package
        params = list(
          ParamInt$new(id = "ntree", default = 200L, lower = 1L, tags = "train"),
          # Only used for continuous models, so can remove from LearnerClassif.
          #ParamDbl$new(id = "sigest", default = NULL, lower = 0, tags = "train"),
          # Only used for continuous models, so can remove from LearnerClassif.
          #ParamInt$new(id = "sigdf", default = 3L, lower = 1L, tags = "train"),
          # Only used for continuous models, so can remove from LearnerClassif.
          #ParamDbl$new(id = "sigquant", default = 0.90, lower = 0, upper = 1, tags = "train"),
          ParamDbl$new(id = "k", default = 2.0, lower = 0, tags = "train"),
          ParamDbl$new(id = "power", default = 2.0, lower = 0, tags = "train"),
          ParamDbl$new(id = "base", default = 0.95, lower = 0, tags = "train"),
          # Not applicable for LearnerRegr
          ParamDbl$new(id = "binaryOffset", default = 0.0, tags = "train"),
          ParamInt$new(id = "ndpost", default = 1000L, lower = 1L, tags = "train"),
          ParamInt$new(id = "nskip", default = 100L, lower = 0L, tags = "train"),
          ParamInt$new(id = "printevery", default = 100L, lower = 0L, tags = "train"),
          ParamInt$new(id = "keepevery", default = 1L, lower = 1L, tags = "train"),
          ParamLgl$new(id = "keeptrainfits", default = TRUE, tags = "train"),
          ParamLgl$new(id = "usequants", default = FALSE, tags = "train"),
          ParamInt$new(id = "numcut", default = 100L, lower = 1L, tags = "train"),
          ParamInt$new(id = "printcutoffs", default = 0, tags = "train"),
          ParamLgl$new(id = "verbose", default = TRUE, tags = "train"),
          ParamLgl$new(id = "keeptrees", default = FALSE, tags = "train"),
          ParamLgl$new(id = "keepcall", default = TRUE, tags = "train"),
          ParamLgl$new(id = "sampleronly", default = FALSE, tags = "train"),
          ParamLgl$new(id = "offset.test", default = FALSE, tags = "predict")
        )
      )
      # Override package defaults.
      # We need keeptrees to be true in order to predict().
      ps$values = list(keeptrees = TRUE)

      super$initialize(
        # see the mlr3book for a description: https://mlr3book.mlr-org.com/extending-mlr3.html
        id = "classif.dbarts",
        packages = "dbarts",
        feature_types = c("integer", "numeric", "factor", "ordered"),
        predict_types = c("response", "prob"),
        param_set = ps,
        # TODO: add importance.
        # Parallel is giving an autotest error.
        properties = c("weights", "twoclass")#, "parallel")
      )
    },

    train_internal = function(task) {
      pars = self$param_set$get_values(tags = "train")

      # Extact just the features from the task data.
      data = task$data(cols = task$feature_names)

      print(class(data))
      print(table(sapply(data, class)))

      outcome = task$data(cols = task$target_names)

      if ("weights" %in% task$properties) {
        pars$weights = task$weights$weight
      }

      # Use the mlr3misc::invoke function (it's similar to do.call())
      # y.train should either be a binary factor or have values {0, 1}
      invoke(dbarts::bart, x.train = data, y.train = outcome,
             .args = pars)
    },

    predict_internal = function(task) {
      pars = self$param_set$get_values(tags = "predict") # get parameters with tag "predict"
      newdata = task$data(cols = task$feature_names) # get newdata
      #type = ifelse(self$predict_type == "response", "response", "prob") # this is for the randomForest package

      # Other possible vars: offset.test, combineChains, ...

      p = invoke(predict, self$model, test = newdata, .args = pars)

      print(names(p))

      # Transform predictions.
      # TODO: confirm that this is the correct element name.
      pred = colMeans(stats::pnorm(p$yhat.test))

      # Return a prediction object with PredictionClassif$new() or PredictionRegr$new()
      if (self$predict_type == "response") {
        # Round probability predictions to 1 or 0.
        PredictionClassif$new(task = task, response = round(pred))
      } else {
        PredictionClassif$new(task = task, prob = pred)
      }
    }

    # Add method for importance, if learner supports that.
    # It must return a sorted (decreasing) numerical, named vector.
    # TODO later.
    # importance = function() { }
  )
)