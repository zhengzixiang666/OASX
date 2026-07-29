part of overview;

class TaskItemView extends StatelessWidget {
  final TaskItemModel model;
  final String status;
  const TaskItemView(this.model, {super.key, this.status = ''});

  @override
  Widget build(BuildContext context) {
    return model.isAllEmpty()
        ? const SizedBox(height: 30)
        : <Widget>[
      _name(context),
      _action(context),
    ]
        .toRow(mainAxisAlignment: MainAxisAlignment.spaceBetween)
        .padding(bottom: 10);
  }

  Widget _name(BuildContext context) {
    return <Widget>[
      Text(model.taskName.tr, style: Theme.of(context).textTheme.labelLarge),
      Text(model.nextRun, style: Theme.of(context).textTheme.labelMedium)
    ].toColumn(crossAxisAlignment: CrossAxisAlignment.start);
  }

  Widget _action(BuildContext context) {
    final apiClient = ApiClient();
    final scriptName = Get.find<NavCtrl>().selectedScript.value;

    Widget settingBtn = OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: () => Get.find<NavCtrl>().switchContent(model.taskName),
        child: Text(I18n.task_setting.tr,
            style: Theme.of(context).textTheme.bodySmall))
        .constrained(maxWidth: 100, maxHeight: 30);

    Widget? extraBtn;
    if (status == 'running' || status == 'pending') {
      extraBtn = OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: () async {
            await apiClient.syncNextRun(scriptName, model.taskName);
          },
          child: Text(I18n.task_postpone.tr,
              style: Theme.of(context).textTheme.bodySmall))
          .constrained(maxWidth: 100, maxHeight: 30);
    } else if (status == 'waiting') {
      extraBtn = OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          onPressed: () async {
            final now = DateTime.now();
            final targetDt =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
            await apiClient.syncNextRun(scriptName, model.taskName, targetDt: targetDt);
          },
          child: Text(I18n.task_run_now.tr,
              style: Theme.of(context).textTheme.bodySmall))
          .constrained(maxWidth: 100, maxHeight: 30);
    }

    return extraBtn != null
        ? <Widget>[extraBtn, settingBtn].toRow(mainAxisSize: MainAxisSize.min)
        : settingBtn;
  }
}
