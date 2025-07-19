#ifndef FLUTTER_MY_APPLICATION_H_
#define FLUTTER_MY_APPLICATION_H_

#include <gtk/gtk.h>
#include <flutter_linux/fl_method_channel.h>

typedef struct _MyApplication MyApplication;
typedef struct _MyApplicationClass MyApplicationClass;

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* native_channel;
  FlMethodChannel* logger_channel;
};

struct _MyApplicationClass {
  GtkApplicationClass parent_class;
};

GType my_application_get_type(void);

/**
 * my_application_new:
 *
 * Creates a new Flutter-based application.
 *
 * Returns: a new #MyApplication.
 */
MyApplication* my_application_new();

#endif  // FLUTTER_MY_APPLICATION_H_
