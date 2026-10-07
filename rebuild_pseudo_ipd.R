# Independent reconstruction of pseudo-IPD from saved KEYNOTE-689 KM coordinates.
# This script does not reproduce the archived survival-model fits or economic base case.

Sys.setlocale("LC_ALL", "Chinese_China.utf8")
suppressPackageStartupMessages(library(openxlsx))
suppressPackageStartupMessages(library(IPDfromKM))
suppressPackageStartupMessages(library(survival))
suppressPackageStartupMessages(library(ggplot2))

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)[1]
if (is.na(script_arg)) stop("Run this file with Rscript.")
package_dir <- dirname(normalizePath(sub("^--file=", "", script_arg),
                                     winslash = "/", mustWork = TRUE))
output_dir <- file.path(package_dir, "derived")
dir.create(output_dir, showWarnings = FALSE)

groups <- c("CPS-10", "CPS-1", "Total population")
series <- c("PFS_TG", "PFS_CG", "OS_TG", "OS_CG")
coordinates <- list()
reconstructed <- list()
fit_lines <- list()
checks <- list()

for (group in groups) {
  for (nm in series) {
    km <- read.xlsx(file.path(package_dir, group, "km_adj.xlsx"), sheet = nm)
    endpoint <- if (startsWith(nm, "PFS")) "EFS" else "OS"
    arm <- if (endsWith(nm, "_TG")) "PSOC" else "SOC"
    id <- paste(group, endpoint, arm, sep = "_")

    prep <- preprocess(dat = km[, c("time", "surv")],
                       trisk = na.omit(km$trisk),
                       nrisk = na.omit(km$nrisk), maxy = 1)
    ipd <- getIPD(prep = prep, armID = if (arm == "PSOC") 1 else 0,
                  tot.events = NULL)$IPD
    if (nrow(ipd) != na.omit(km$nrisk)[1]) {
      stop("Reconstructed sample size disagrees with KM risk table: ", id)
    }

    fit <- survfit(Surv(time, status) ~ 1, data = ipd)
    estimate_at <- function(t) {
      ix <- which(fit$time <= t)
      if (length(ix) == 0) 1 else fit$surv[max(ix)]
    }
    km_estimate <- vapply(km$time, estimate_at, numeric(1))
    largest_gap <- which.max(abs(km$surv - km_estimate))
    source_36 <- km$surv[max(which(km$time <= 36))]
    checks[[id]] <- data.frame(
      group = group, endpoint = endpoint, arm = arm,
      n = nrow(ipd), reconstructed_events = sum(ipd$status),
      risk_count_at_zero = na.omit(km$nrisk)[1],
      digitized_survival_at_36_months = source_36,
      reconstructed_survival_at_36_months = estimate_at(36),
      max_abs_km_point_difference = abs(km$surv[largest_gap] - km_estimate[largest_gap]),
      month_of_max_difference = km$time[largest_gap]
    )
    coordinates[[id]] <- data.frame(group = group, endpoint = endpoint,
                                    arm = arm, point_id = seq_len(nrow(km)), km)
    reconstructed[[id]] <- data.frame(group = group, endpoint = endpoint,
                                      arm = arm, pseudo_id = seq_len(nrow(ipd)), ipd)
    fit_lines[[id]] <- data.frame(group = group, endpoint = endpoint, arm = arm,
                                  time = c(0, fit$time), surv = c(1, fit$surv))
  }
}

coordinate_data <- do.call(rbind, coordinates)
ipd_data <- do.call(rbind, reconstructed)
fit_data <- do.call(rbind, fit_lines)
check_data <- do.call(rbind, checks)
rownames(coordinate_data) <- NULL
rownames(ipd_data) <- NULL
rownames(check_data) <- NULL
write.csv(coordinate_data, file.path(output_dir, "digitized_km_coordinates.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(ipd_data, file.path(output_dir, "reconstructed_pseudo_ipd.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(check_data, file.path(output_dir, "reconstruction_check.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

plot <- ggplot() +
  geom_step(data = fit_data,
            aes(x = time, y = surv, colour = arm), linewidth = 0.62) +
  geom_point(data = coordinate_data,
             aes(x = time, y = surv, colour = arm), size = 0.38, alpha = 0.42) +
  facet_grid(group ~ endpoint) +
  scale_colour_manual(values = c(PSOC = "#355C7D", SOC = "#777777")) +
  coord_cartesian(xlim = c(0, 66), ylim = c(0, 1)) +
  labs(x = "Months", y = "Survival probability", colour = NULL,
       title = "Digitized KEYNOTE-689 KM points and reconstructed pseudo-IPD KM",
       subtitle = "Points: digitized published curves; lines: KM from reconstructed pseudo-IPD") +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom", plot.title = element_text(face = "bold"))
ggsave(file.path(output_dir, "KM_reconstruction_validation.png"), plot,
       width = 10.5, height = 8, units = "in", dpi = 300, bg = "white")
ggsave(file.path(output_dir, "KM_reconstruction_validation.pdf"), plot,
       width = 10.5, height = 8, units = "in", device = cairo_pdf)

print(check_data)
