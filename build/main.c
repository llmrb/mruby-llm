#include <stdlib.h>
#include <stdio.h>
#include <mruby.h>
#include <mruby/array.h>
#include <mruby/error.h>
#include <mruby/irep.h>
#include <mruby/string.h>
#include <mruby/variable.h>

extern const uint8_t __MRUBY_LLM_IREP_SYMBOL__[];

static void
set_argv(mrb_state *mrb, int argc, char **argv)
{
  mrb_value args = mrb_ary_new_capa(mrb, argc > 1 ? argc - 1 : 0);
  int i;
  for (i = 1; i < argc; i++) {
    mrb_ary_push(mrb, args, mrb_str_new_cstr(mrb, argv[i]));
  }
  mrb_define_global_const(mrb, "ARGV", args);
}

int
main(int argc, char **argv)
{
  mrb_state *mrb = mrb_open();
  if (!mrb) {
    fputs("invalid mrb_state\n", stderr);
    return EXIT_FAILURE;
  }
  set_argv(mrb, argc, argv);
  mrb_load_irep(mrb, __MRUBY_LLM_IREP_SYMBOL__);
  if (mrb->exc) {
    mrb_print_error(mrb);
    mrb_close(mrb);
    return EXIT_FAILURE;
  }
  mrb_close(mrb);
  return EXIT_SUCCESS;
}
