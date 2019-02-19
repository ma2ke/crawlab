from app import api
from db.manager import db_manager
from routes.base import BaseApi
from utils import jsonify


class TaskApi(BaseApi):
    col_name = 'tasks'

    arguments = (
        ('deploy_id', str),
        ('file_path', str)
    )

    def get(self, id=None):
        tasks = db_manager.list('tasks', {}, limit=1000)
        items = []
        for task in tasks:
            _task = db_manager.get('tasks_celery', id=task['_id'])
            _spider = db_manager.get('spiders', id=str(task['spider_id']))
            task['status'] = _task['status']
            task['spider_name'] = _spider['name']
            items.append(task)
        return jsonify({
            'status': 'ok',
            'items': items
        })


# add api to resources
api.add_resource(TaskApi,
                 '/api/tasks',
                 '/api/tasks/<string:id>'
                 )
